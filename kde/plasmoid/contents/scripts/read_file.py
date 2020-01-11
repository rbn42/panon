"""
panon client

Usage:
  freetile [options] <effect> <file>
  freetile -h | --help

Options:
  -h --help                     Show this screen.
  --debug                       Debug
"""
from helper import config_effect_home, applet_effect_home, read_file
from docopt import docopt
import os.path
arguments = docopt(__doc__)
effect_name = arguments['<effect>']

if effect_name.endswith(' '):
    effect_name = effect_name[:-1]
    effect_home = config_effect_home
else:
    effect_home = applet_effect_home
s = read_file(os.path.join(effect_home, effect_name, arguments['<file>']))
print(s)
