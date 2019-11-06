import asyncio
import time
import base64
import io
import numpy as np
import os
import json
import websockets

import sys
server_port = int(sys.argv[1])


async def hello(websocket, path):
    for _ in range(10):
        img = await websocket.recv()
    open('/dev/shm/t.html', 'w').write("""
    <img src="%s" ></img>
    """ % img)
    if os.path.exists('/usr/bin/firefox'):
        os.system('firefox /dev/shm/t.html ')
    else:
        os.system('chromium /dev/shm/t.html ')
    sys.exit()


start_server = websockets.serve(hello, "localhost", server_port)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
