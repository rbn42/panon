"""
panon client

Usage:
  main [options] <port> 
  main -h | --help

Options:
  -h --help                     Show this screen.
  --device-index=I              Device index.
  --fps=F                       Fps [default: 30]
  --reduce-bass                 
  --gldft
  --bass-resolution-level=L     [default: 1]
  --backend=B                   [default: pyaudio]
  --fifo-path=P
  --debug                       Debug
"""
import asyncio
import numpy as np
import json
import websockets
from . import spectrum
from .decay import Decay
from . import source

import sys

from docopt import docopt
arguments = docopt(__doc__)

server_port = int(arguments['<port>'])
cfg_fps = int(arguments['--fps'])
bassResolutionLevel = int(arguments['--bass-resolution-level'])
reduceBass = arguments['--reduce-bass']
use_glDFT = arguments['--gldft']

sample_rate = 44100
beatsDetector = None

if arguments['--backend'] == 'pyaudio':
    spectrum_source = source.PyaudioSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'], cfg_fps)
elif arguments['--backend'] == 'fifo':
    spectrum_source = source.FifoSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--fifo-path'], cfg_fps)
#elif arguments['--backend'] == 'sounddevice':
#    spectrum_source = source.SounddeviceSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'])
elif arguments['--backend'] == 'soundcard':
    spectrum_source = source.SoundCardSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'], cfg_fps)
    from . import beat
    if beat.canImportAubio():
        beatsDetector = beat.BeatsDetector(spectrum.NUM_CHANNEL, sample_rate, cfg_fps)
else:
    assert False


async def mainloop():
    async with websockets.connect(f"ws://localhost:{server_port}") as websocket:

        spec = spectrum.Spectrum()
        decay = Decay()

        from .convertor import Numpy2Str
        n2s = Numpy2Str()

        spectrum_data = None
        isBeat = False

        while True:

            if not use_glDFT and spectrum_data is None:
                # Set fps to 2 to lower CPU usage, when audio is unavailable.
                latest_wave_data = spectrum_source.read(fps=2)
            else:
                latest_wave_data = spectrum_source.read()
                isBeat = beatsDetector is not None and beatsDetector.isBeat(latest_wave_data)
            if latest_wave_data.dtype.type is np.float32:
                latest_wave_data = np.asarray(latest_wave_data * (2**16), dtype='int16')

            if use_glDFT:
                await websocket.send(n2s.convert_int16(latest_wave_data))
                continue

            wave_hist = spec.updateHistory(latest_wave_data)
            data = spec.computeSpectrum(wave_hist, bassResolutionLevel=bassResolutionLevel, reduceBass=reduceBass)

            spectrum_data = decay.process(data)
            if spectrum_data is None:
                await websocket.send(b'')
            else:
                spectrum_data = np.clip(spectrum_data[1:] / 3.0, 0, 0.99) * 256
                wave_data = latest_wave_data
                wave_max = np.max(np.abs(wave_data))
                wave_data = (wave_data + wave_max) / wave_max / 2 * 256

                spectrum_data_m = n2s.convert(spectrum_data)
                wave_data_m = n2s.convert(wave_data)

                await websocket.send(np.asarray( spectrum_data,dtype='uint8').tobytes())
                continue
                    
                await websocket.send(json.dumps({
                    'spectrum': spectrum_data_m,
                    'wave': wave_data_m,
                    'beat': isBeat,
                }))


asyncio.get_event_loop().run_until_complete(mainloop())
