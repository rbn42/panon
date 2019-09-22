#!/usr/bin/env python
# WS client example
import asyncio
import os
import websockets

async def hello():
    uri = "ws://localhost:8765"
    async with websockets.connect(uri) as websocket:
        await websocket.send('')
        img= await websocket.recv()
        open('/dev/shm/t.html','w').write("""
        <img src="%s" ></img>
        """%img)
        os.system('firefox /dev/shm/t.html ')

        

asyncio.get_event_loop().run_until_complete(hello())

