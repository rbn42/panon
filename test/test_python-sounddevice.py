import sounddevice as sd
#import soundfile as sf
import numpy as np
import time

import queue

if __name__ == '__main__':

    #print(sd.query_devices())

    device_info = sd.query_devices(None, 'input')
    #print(device_info)

    print('Make sure you are playing music when run this script')
    stream = sd.InputStream(samplerate=44100, device=None, channels=2)
    stream.start()
    import time
    time.sleep(2)
    data, _ = stream.read(stream.read_available)

    _max = np.max(data)
    _min = np.min(data)
    _sum = np.sum(data)
    print(_max, _min, _sum)
    if _max > 0:
        print('succeeded to catch audio')
    else:
        print('failed to catch audio')
