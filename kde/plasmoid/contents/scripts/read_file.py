"""
panon client

Usage:
  freetile [options] <effect> <file>
  freetile -h | --help

Options:
  -h --help                     Show this screen.
  --debug                       Debug
"""
from pathlib import Path
from docopt import docopt
from helper import effect_dirs, read_file

arguments = docopt(__doc__)
effect_name = arguments['<effect>']

for effect_dir in effect_dirs:
    effect = effect_dir / effect_name
    if effect.is_dir():
        print(read_file(effect / arguments['<file>']))
