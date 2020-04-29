import sys
import json
from pathlib import Path

from docopt import docopt

from .helper import effect_dirs, read_file, read_file_lines
from . import get_effect_list

import json, base64

effect_id, effect_arguments = json.loads(base64.b64decode(sys.argv[1]))

effect_list = get_effect_list.get_list()
effect = None

# Set a default effect.
for e in effect_list:
    if e.name == 'default':
        effect = e

for e in effect_list:
    if e.id == effect_id:
        effect = e


def hex2vec4(value):
    assert value.startswith('#')
    value = value[1:]
    nums = [int(value[i:i + 2], base=16) / 256 for i in range(0, len(value), 2)]
    if len(nums) < 4:
        nums.insert(0,1)
    assert len(nums) == 4
    return "vec4(%f,%f,%f,%f)" % tuple(nums[1:]+num[:1])


def format_value(type_, value):
    if type_ == 'color':
        return hex2vec4(value)
    return value


def build_source(files, main_file: Path, meta_file: Path = None, effect_arguments=None):
    if not main_file.exists():
        return ''
    arguments_map = {}
    # If meta_file exists, construct a key-value map to store arguments' names and values.
    if meta_file is not None and meta_file.exists():
        meta = json.loads(meta_file.read_bytes())
        arguments_map = {arg['name']: format_value(arg['type'], value) for arg, value in zip(meta['arguments'], effect_arguments)}

    # Extract glsl version
    version = next(read_file_lines(main_file))
    source = version
    for path in files:
        if path == main_file:
            for line in list(read_file_lines(path))[1:]:
                lst = line.split()
                if len(lst) >= 3:
                    # Search for used arguments(start with $) in macro definitions.
                    if lst[0] == '#define' and lst[2].startswith('$'):
                        key = lst[2][1:]
                        # Raise an error when the value of an argument is not found.
                        if key not in arguments_map:
                            json.dump({"error_code": 1}, sys.stdout)
                            sys.exit()
                        lst[2] = arguments_map[key]
                        line = ' '.join(lst) + '\n'
                source += line
        else:
            source += read_file(path)
    return source


def texture_uri(path: Path):
    if path.exists():
        return str(path.absolute())
    return ''


applet_effect_home = effect_dirs[-1]

image_shader_path = Path(effect.path)
if not effect.name.endswith('.frag'):
    image_shader_path /= 'image.frag'

image_shader_files = [
    applet_effect_home / 'hsluv-glsl.fsh',
    applet_effect_home / 'utils.fsh',
    applet_effect_home / 'shadertoy-api-head.fsh',
    image_shader_path,
    applet_effect_home / 'shadertoy-api-foot.fsh',
]

if effect.name.endswith('.frag'):
    obj = {'image_shader': build_source(image_shader_files, image_shader_path)}
else:
    obj = {
        'image_shader':
        build_source(
            image_shader_files,
            image_shader_path,
            Path(effect.path) / 'meta.json',
            effect_arguments,
        ),
        'buffer_shader':
        build_source(
            [
                applet_effect_home / 'hsluv-glsl.fsh',
                applet_effect_home / 'utils.fsh',
                applet_effect_home / 'shadertoy-api-head.fsh',
                Path(effect.path) / 'buffer.frag',
                applet_effect_home / 'shadertoy-api-foot-buffer.fsh',
            ],
            Path(effect.path) / 'buffer.frag',
            Path(effect.path) / 'meta.json',
            effect_arguments,
        ),
        'texture':
        texture_uri(Path(effect.path) / 'texture.png'),
    }

json.dump(obj, sys.stdout)
