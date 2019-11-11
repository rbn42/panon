"""
panon client

Usage:
  freetile [options] <port> 
  freetile -h | --help

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
    time.sleep(30)

server_port = int(arguments['<port>'])
cfg_fps = int(arguments['--fps'])
bassResolutionLevel = int(arguments['--bass-resolution-level'])
reduceBass = arguments['--reduce-bass'] is not None

import time
spectrum_decay = 0.01
sample_rate = 44100
expected_buffer_size = sample_rate // cfg_fps

if arguments['--backend'] == 'pyaudio':
    spectrum_source = source.PyaudioSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'])
elif arguments['--backend'] == 'fifo':
    spectrum_source = source.FifoSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--fifo-path'], cfg_fps)
elif arguments['--backend'] == 'sounddevice':
    spectrum_source = source.SounddeviceSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'])
elif arguments['--backend'] == 'soundcard':
    spectrum_source = source.SoundCardSource(spectrum.NUM_CHANNEL, sample_rate, arguments['--device-index'], expected_buffer_size)
else:
    assert False

spec = spectrum.Spectrum(spectrum_source, )
decay = Decay()
decay_wave = Decay()

from .convertor import Numpy2Str
n2s = Numpy2Str()


async def hello():
    uri = f"ws://localhost:{server_port}"
    async with websockets.connect(uri) as websocket:

        old_timestamp = time.time()
        img_data = None

        while True:
            latest_wave_data = spectrum_source.readlatest(expected_buffer_size, spec.get_max_wave_size())
            wave_hist = spec.updateHistory(latest_wave_data)
            data = spec.computeSpectrum(wave_hist, fps=cfg_fps, bassResolutionLevel=bassResolutionLevel, reduceBass=reduceBass)

            spectrum_data, local_max = decay.process(data, wave=False)
            if spectrum_data is None and (local_max is None or np.max(local_max) < 0.3):
                await websocket.send('')
            else:
                if spectrum_data is not None:
                    spectrum_data = np.clip(spectrum_data[1:] / 3.0, 0, 0.99) * 256
                    wave_data = wave_hist[-spectrum_data.shape[0]:]
                    wave_max = np.max(np.abs(wave_data))
                    wave_data = (wave_data + wave_max) / wave_max / 2 * 256
                else:
                    wave_data = None
                if local_max is not None:
                    local_max = np.clip(local_max[1:] / 3.0, 0, 0.99) * 256
                spectrum_data_m = n2s.convert(spectrum_data)
                spectrum_max_m = n2s.convert(local_max)
                wave_data_m = n2s.convert(wave_data)
                data = None
                local_max = None

                await websocket.send(json.dumps({
                    'spectrum': spectrum_data_m,
                    'max_spectrum': spectrum_max_m,
                    'wave': wave_data_m,
                }))

            new_timestamp = time.time()
            time_sleep = max(0, 1 / cfg_fps - (new_timestamp - old_timestamp))
            old_timestamp = new_timestamp
            time.sleep(time_sleep)


asyncio.get_event_loop().run_until_complete(hello())
