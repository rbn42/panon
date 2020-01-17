"""
panon client

Usage:
  freetile [options] [<effect-arguments>...]
  freetile -h | --help

Options:
  -h --help                     Show this screen.
  --random-effect
  --effect-name=N
  --debug                       Debug
"""
from docopt import docopt
import sys
import json
import os.path

from helper import config_effect_home, applet_effect_home, read_file, read_file_lines

arguments = docopt(__doc__)
effect_name = arguments['--effect-name']
effect_arguments = arguments['<effect-arguments>']
if arguments['--random-effect']:
    import random
    import get_effect_list
    effect_list = get_effect_list.get_list()
    effect_name = random.choice(effect_list)
    effect_arguments = []

if effect_name.endswith(' '):
    effect_name = effect_name[:-1]
    effect_home = config_effect_home
else:
    effect_home = applet_effect_home


def value2str(value):
    t = type(value)
    if t == int:
        return str(value)
    elif t == float:
        return str(value)
    elif t == bool:
        return 'true' if value else 'false'


def build_source(files, main_file, meta_file=None, effect_arguments=None):
    if not os.path.exists(main_file):
        return ''
    arguments_map = {}
    if meta_file is not None:
        if os.path.exists(meta_file):
            meta = json.load(open(meta_file, 'rb'))
            meta_arg = meta['arguments']
            arguments_map = {arg['name']: arg['default'] for arg in meta_arg}
            if len(effect_arguments) > 0:
                for i in range(len(meta_arg)):
                    value = effect_arguments[i]
                    if meta_arg[i]['type'] == 'double':
                        value = float(value)
                    elif meta_arg[i]['type'] == 'int':
                        value = int(value)
                    elif meta_arg[i]['type'] == 'bool':
                        value = (value == 'true')
                    arguments_map[meta_arg[i]['name']] = value

    version = next(read_file_lines(main_file))
    source = version
    for path in files:
        if path == main_file:
            for line in list(read_file_lines(path))[1:]:
                lst = line.split()
                if len(lst) >= 3:
                    if lst[2].startswith('$'):
                        lst[2] = value2str(arguments_map[lst[2][1:]])
                        line = ' '.join(lst) + '\n'
                source += line
        else:
            source += read_file(path)
    return source

def texture_uri(path):
    if os.path.exists(path):
        return os.path.abspath(path)
    return ''

if effect_name.endswith('.frag'):
    obj = {
        'image_shader':
        build_source([
            os.path.join(applet_effect_home, 'hsluv-glsl.fsh'),
            os.path.join(applet_effect_home, 'utils.fsh'),
            os.path.join(applet_effect_home, 'shadertoy-api-head.fsh'),
            os.path.join(effect_home, effect_name),
            os.path.join(applet_effect_home, 'shadertoy-api-foot.fsh'),
        ], os.path.join(effect_home, effect_name))
    }
    json.dump(obj, sys.stdout)
elif effect_name.endswith('/'):
    obj = {
        'image_shader':
        build_source(
            [
                os.path.join(applet_effect_home, 'hsluv-glsl.fsh'),
                os.path.join(applet_effect_home, 'utils.fsh'),
                os.path.join(applet_effect_home, 'shadertoy-api-head.fsh'),
                os.path.join(effect_home, effect_name, 'image.frag'),
                os.path.join(applet_effect_home, 'shadertoy-api-foot.fsh'),
            ],
            os.path.join(effect_home, effect_name, 'image.frag'),
            os.path.join(effect_home, effect_name, 'meta.json'),
            effect_arguments,
        ),
        'buffer_shader':
        build_source(
            [
                os.path.join(applet_effect_home, 'shadertoy-api-head.fsh'),
                os.path.join(effect_home, effect_name, 'buffer.frag'),
                os.path.join(applet_effect_home, 'shadertoy-api-foot-buffer.fsh'),
            ],
            os.path.join(effect_home, effect_name, 'buffer.frag'),
            os.path.join(effect_home, effect_name, 'meta.json'),
            effect_arguments,
        ),
        'texture':
        texture_uri(os.path.join(effect_home, effect_name, 'texture.png')),
    }
    json.dump(obj, sys.stdout)
