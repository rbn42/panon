import pyaudio
import json
p = pyaudio.PyAudio()
l = []
for i in range(p.get_device_count()):
    obj=p.get_device_info_by_index(i)
    if obj['maxInputChannels']<1:
        # Remove devices with no input channel
        continue
    l.append(obj)
s = json.dumps(l)
print(s)
