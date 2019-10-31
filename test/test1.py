#!/usr/bin/env python
# WS client example
import asyncio
import os
import websockets


async def hello():
    uri = "ws://localhost:8765"
    async with websockets.connect(uri) as websocket:
        await websocket.send('{"fps":30}')
        img = await websocket.recv()
        open('/dev/shm/t.html', 'w').write("""
        <img src="%s" ></img>
        """ % img)
        if os.path.exists('/usr/bin/firefox'):
            os.system('firefox /dev/shm/t.html ')
        else:
            os.system('chromium /dev/shm/t.html ')


asyncio.get_event_loop().run_until_complete(hello())
