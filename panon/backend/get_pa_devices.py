import json
import soundcard as sc

print(json.dumps([{'id': mic.id, 'name': mic.name} for mic in sc.all_microphones(include_loopback=True)]))
