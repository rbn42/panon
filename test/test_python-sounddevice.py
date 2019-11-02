import sounddevice as sd
#import soundfile as sf
import numpy as np
import time

import queue

if __name__=='__main__':

    #print(sd.query_devices())

    device_info = sd.query_devices(None, 'input')
    #print(device_info)

    q = queue.Queue()

    def callback(indata, frames, time, status):
        """This is called (from a separate thread) for each audio block."""
        if status:
            print(status, file=sys.stderr)
        q.put(indata.copy())

    print('Make sure you are playing music when run this script')
    data=[]
    with sd.InputStream(samplerate=44100, device=None,
                            channels=2, callback=callback):
        for _ in range(20):
            data.append(q.get())
    data=np.concatenate(data,axis=0)

    _max = np.max(data)
    _min = np.min(data)
    _sum = np.sum(data)
    print(_max, _min, _sum)
    if _max > 0:
        print('succeeded to catch audio')
    else:
        print('failed to catch audio')
 
