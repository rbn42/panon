"""
panon client

Usage:
  main [options] <url> 
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
  --enable-wave-data
  --enable-spectrum-data
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

import sys
from .. import logger
logger.log('argv: %s', sys.argv[1:])

arguments = docopt(__doc__)
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
    async with websockets.connect(arguments['<url>']) as websocket:

        spec = spectrum.Spectrum()
        decay = Decay()

        from .convertor import Numpy2Str
        n2s = Numpy2Str()

        spectrum_data = True    #None
        isBeat = False

        logger.log('loop')
        while True:

            if type(spectrum_source) is source.SoundCardSource:
                if spectrum_source.smart_device_id == '':
                    spectrum_source.update_smart_device()

            if not use_glDFT and spectrum_data is None:
                # Set fps to 2 to lower CPU usage, when audio is unavailable.
                latest_wave_data = spectrum_source.read(fps=2)
                if type(spectrum_source) is source.SoundCardSource:
                    spectrum_source.update_smart_device()
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
                await websocket.send('')
            else:

                obj = {
                    'beat': isBeat,
                }
                if arguments['--enable-wave-data']:
                    wave_data = latest_wave_data
                    wave_max = np.max(np.abs(wave_data))
                    wave_data = (wave_data + wave_max) / wave_max / 2 * 256
                    wave_data_m = n2s.convert(wave_data)
                    obj['wave'] = wave_data_m
                if arguments['--enable-spectrum-data']:
                    spectrum_data = np.clip(spectrum_data[1:] / 3.0, 0, 0.99) * 256
                    spectrum_data_m = n2s.convert(spectrum_data)
                    # When only spectrum data is enabled, send raw data to reduce cpu usage.
                    if not arguments['--enable-wave-data']:
                        await websocket.send(spectrum_data_m)
                        continue
                    obj['spectrum'] = spectrum_data_m

                await websocket.send(json.dumps(obj))


asyncio.get_event_loop().run_until_complete(mainloop())
