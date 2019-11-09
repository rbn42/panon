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
import base64
import io
import numpy as np
import json
import websockets
from PIL import Image
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


async def hello():
    uri = f"ws://localhost:{server_port}"
    async with websockets.connect(uri) as websocket:

        old_timestamp = time.time()
        img_data = None

        while True:
            latest_wave_data = spectrum_source.readlatest(expected_buffer_size, spec.get_max_wave_size())
            hist = spec.updateHistory(latest_wave_data)
            data = spec.getData(hist, fps=cfg_fps, bassResolutionLevel=bassResolutionLevel, reduceBass=reduceBass)

            data, local_max = decay.process(data)

            if data is None:
                if local_max is None:
                    # Sending empty string means stop rendering
                    message = ''
                elif np.max(local_max) > 0.3:
                    # Don't stop rendering until local_max fall below 0.3
                    data = np.zeros(local_max.shape)
                else:
                    # Sending empty string means stop rendering
                    message = ''

            if data is not None:

                data = np.clip(data / 3.0, 0, 0.99)
                local_max = np.clip(local_max / 3.0, 0, 0.99)

                if img_data is None:
                    img_data = np.zeros((4, data.shape[1], 3), dtype='uint8')
                    # img_data[:, :, 3] =  255

                # texture(tex1, vec2(qt_TexCoord0.x,1/8.)) ;
                img_data[0, :, :2] = np.rollaxis(data, 1, 0) * 256
                # texture(tex1, vec2(qt_TexCoord0.x,3/8.)) ;
                img_data[1, :, :2] = np.rollaxis(local_max, 1, 0) * 256
                # Reserved data channels
                # texture(tex1, vec2(qt_TexCoord0.x,5/8.)) ;
                # img_data[2, :, :2]
                # texture(tex1, vec2(qt_TexCoord0.x,7/8.)) ;
                # img_data[3, :, :2]

                #头部一些奇怪的数据去掉
                image = Image.fromarray(img_data[:, 1:, :])
                #converts PIL image to datauri
                data = io.BytesIO()
                image.save(data, "png")
                message = 'data:img/png;base64,' + base64.b64encode(data.getvalue()).decode()

            await websocket.send(message)

            new_timestamp = time.time()
            time_sleep = max(0, 1 / cfg_fps - (new_timestamp - old_timestamp))
            old_timestamp = new_timestamp
            time.sleep(time_sleep)


asyncio.get_event_loop().run_until_complete(hello())
