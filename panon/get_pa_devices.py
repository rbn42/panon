from . import pulseaudio as sc
import json

l = []
for mic in sc.all_microphones(exclude_monitors=False):
    l.append(mic.id)
s = json.dumps(l)
print(s)
