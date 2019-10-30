import pyaudio
import json
p = pyaudio.PyAudio()
l = []
for i in range(p.get_device_count()):
    l.append(p.get_device_info_by_index(i))
s = json.dumps(l)
print(s)
