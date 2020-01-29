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
  --bass-resolution-level=L     [default: 1]
  --backend=B                   [default: pyaudio]
  --fifo-path=P
  --debug                       Debug
"""
import asyncio
import time
import numpy as np
import json
import websockets
from . import spectrum
from .decay import Decay
from . import source

import sys

from docopt import docopt
arguments = docopt(__doc__)
if arguments['--debug']:
    import time
    #time.sleep(30)

server_port = int(arguments['<port>'])
cfg_fps = int(arguments['--fps'])
bassResolutionLevel = int(arguments['--bass-resolution-level'])
reduceBass = arguments['--reduce-bass'] is not None

import time
sample_rate = 44100

if arguments['--backend'] == 'pyaudio':
    spectrum_source = source.PyaudioSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'], cfg_fps)
elif arguments['--backend'] == 'fifo':
    spectrum_source = source.FifoSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--fifo-path'], cfg_fps)
#elif arguments['--backend'] == 'sounddevice':
#    spectrum_source = source.SounddeviceSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'])
elif arguments['--backend'] == 'soundcard':
    spectrum_source = source.SoundCardSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'], cfg_fps)
else:
    assert False

spec = spectrum.Spectrum()
decay = Decay()

from .convertor import Numpy2Str
n2s = Numpy2Str()


async def hello():
    uri = f"ws://localhost:{server_port}"
    async with websockets.connect(uri) as websocket:

        while True:

            latest_wave_data = spectrum_source.read()
            wave_hist = spec.updateHistory(latest_wave_data)
            data = spec.computeSpectrum(wave_hist, bassResolutionLevel=bassResolutionLevel, reduceBass=reduceBass)

            spectrum_data = decay.process(data)
            if spectrum_data is None:
                await websocket.send('')
            else:
                spectrum_data = np.clip(spectrum_data[1:] / 3.0, 0, 0.99) * 256
                wave_data = wave_hist[-spectrum_data.shape[0]:]
                wave_max = np.max(np.abs(wave_data))
                wave_data = (wave_data + wave_max) / wave_max / 2 * 256

                spectrum_data_m = n2s.convert(spectrum_data)
                wave_data_m = n2s.convert(wave_data)

                await websocket.send(json.dumps({
                    'spectrum': spectrum_data_m,
                    'wave': wave_data_m,
                }))


asyncio.get_event_loop().run_until_complete(hello())
