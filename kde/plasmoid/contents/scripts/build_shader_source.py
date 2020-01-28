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
import sys
import json
from pathlib import Path

from docopt import docopt

from helper import effect_dirs, read_file, read_file_lines

arguments = docopt(__doc__)
effect_name = arguments['--effect-name']
effect_arguments = arguments['<effect-arguments>']
if arguments['--random-effect']:
    import random
    import get_effect_list
    effect_list = get_effect_list.get_list()
    effect_name = random.choice(effect_list)
    effect_arguments = []

for effect_dir in effect_dirs:
    if (effect_dir / effect_name).exists():
        effect_home = effect_dir
        break
else:
    raise RuntimeError(f'Could not find shader {effect_name} in any of {effect_dirs}')


def value2str(value):
    if isinstance(value, int):
        return str(value)
    elif isinstance(value, float):
        return str(value)
    elif isinstance(value, bool):
        return str(bool(value)).lower()


def build_source(files, main_file: Path, meta_file: Path = None, effect_arguments=None):
    if not main_file.exists():
        return ''
    arguments_map = {}
    if meta_file is not None and meta_file.exists():
        meta = json.loads(meta_file.read_bytes())
        meta_arg = meta['arguments']
        arguments_map = {arg['name']: arg['default'] for arg in meta_arg}
        if len(effect_arguments) > 0:
            for a, value in zip(meta_arg, effect_arguments):
                if a['type'] == 'double':
                    value = float(value)
                elif a['type'] == 'int':
                    value = int(value)
                elif a['type'] == 'bool':
                    value = value == 'true'
                arguments_map[a['name']] = value

    version = next(read_file_lines(main_file))
    source = version
    for path in files:
        if path == main_file:
            for line in list(read_file_lines(path))[1:]:
                lst = line.split()
                if len(lst) >= 3:
                    if lst[2].startswith('$'):
                        key =lst[2][1:]
                        if key not in arguments_map:
                            json.dump({"error_code":1}, sys.stdout)
                            sys.exit()
                        lst[2] = value2str(arguments_map[key])
                        line = ' '.join(lst) + '\n'
                source += line
        else:
            source += read_file(path)
    return source

def texture_uri(path: Path):
    if path.exists():
        return path.absolute()
    return ''

applet_effect_home = effect_dirs[-1]

image_shader_path = effect_home / effect_name
if not effect_name.endswith('.frag'):
    image_shader_path /= 'image.frag'

image_shader_files = [
    applet_effect_home / 'hsluv-glsl.fsh',
    applet_effect_home / 'utils.fsh',
    applet_effect_home / 'shadertoy-api-head.fsh',
    image_shader_path,
    applet_effect_home / 'shadertoy-api-foot.fsh',
]

if effect_name.endswith('.frag'):
    obj = {
        'image_shader':
        build_source(image_shader_files, image_shader_path)
    }
else:
    obj = {
        'image_shader':
        build_source(
            image_shader_files,
            image_shader_path,
            effect_home / effect_name / 'meta.json',
            effect_arguments,
        ),
        'buffer_shader':
        build_source(
            [
                applet_effect_home / 'shadertoy-api-head.fsh',
                effect_home / effect_name / 'buffer.frag',
                applet_effect_home / 'shadertoy-api-foot-buffer.fsh',
            ],
            effect_home / effect_name / 'buffer.frag',
            effect_home / effect_name / 'meta.json',
            effect_arguments,
        ),
        'texture':
        texture_uri(effect_home / effect_name / 'texture.png'),
    }

json.dump(obj, sys.stdout)
