"""
Read a file of a specified visual effect.

Usage:
  main [options] <effect-id> <file>
  main -h | --help

Options:
  -h --help                     Show this screen.
  --debug                       Debug
"""
from pathlib import Path
from docopt import docopt
from helper import effect_dirs, read_file
import get_effect_list

arguments = docopt(__doc__)
effect_id = arguments['<effect-id>']

for effect in get_effect_list.get_list():
    if effect.id == effect_id:
        print(read_file(Path(effect.path) / arguments['<file>']))
        break
