import asyncio
import time
import base64
import io
import numpy as np
import json
import websockets
from PIL import Image
from . import spectrum

port = 8765
import sys
if len(sys.argv) > 1:
    port = int(sys.argv[1])

s = spectrum.Spectrum(60, 0.01)


async def hello(websocket, path):

    config = await websocket.recv()
    config = json.loads(config)
    print('config', config)

    old_timestamp = time.time()
    img_data = None

    while True:
        data = s.getData(**config)
        if data is None:
            data = ''
        else:
            data = data / 3.0
            data = np.clip(data, 0, 0.99)

            #转换到datauri,这样可以直接作为texture被opengl处理
            #比起http直接传输png来说,这个应该相对还是有些优势,至少少了重复的http握手
            if img_data is None:
                img_data = np.zeros((3, data.shape[1], 4), dtype='uint8')
            img_data[:, :, 0] = data[0] * 256
            img_data[:, :, 1] = data[1] * 256

            #头部一些奇怪的数据去掉
            image = Image.fromarray(img_data[:, 1:, :])
            #converts PIL image to datauri
            data = io.BytesIO()
            #格式用bmp,因为这个尺寸特殊,用png也没压缩的好处
            image.save(data, "bmp")
            data = 'data:img/bmp;base64,' + base64.b64encode(data.getvalue()).decode()

        await websocket.send(data)

        new_timestamp = time.time()
        time_sleep = max(0, 1 / config['fps'] - (new_timestamp - old_timestamp))
        old_timestamp = new_timestamp
        try:
            config = await asyncio.wait_for(websocket.recv(), timeout=time_sleep)
            config = json.loads(config)
            print('new config', config)
        except asyncio.TimeoutError:
            pass


start_server = websockets.serve(hello, "localhost", port)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
