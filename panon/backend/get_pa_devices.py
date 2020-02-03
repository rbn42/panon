from soundcard import pulseaudio as sc
import json

l = []
for mic in sc.all_microphones(exclude_monitors=False):
    l.append({'id': mic.id, 'name': mic.name})
s = json.dumps(l)
print(s)
