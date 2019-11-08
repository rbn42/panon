"""
Requires https://github.com/bastibe/SoundCard
"""
import soundcard as sc

default_mic = sc.default_microphone()
print('Make sure you are playing music when run this script')
data = default_mic.record(samplerate=48000, numframes=48000)
print('Make sure you are playing music when run this script')

_max = np.max(data)
_min = np.min(data)
_sum = np.sum(data)
print(_max, _min, _sum)
if _max > 0:
    print('succeeded to catch audio')
else:
    print('failed to catch audio')
