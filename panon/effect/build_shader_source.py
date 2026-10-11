"""
Build the shaders of a visual effect.

Qt 6 only accepts pre-compiled shaders (.qsb files). This module assembles
the GLSL source of an effect, converts it to the Vulkan-style GLSL expected
by qsb, compiles it and prints the paths of the compiled shaders as JSON.

Usage:
  python3 -m panon.effect.build_shader_source <json [effect id, argument values]>
"""
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

from .helper import applet_effect_home, cache_dir, read_file
from . import get_effect_list
from .. import logger

# Error codes reported to ShaderSource.qml
ERROR_UNDECLARED_ARGUMENT = 'undeclared-argument'
ERROR_COMPILATION = 'compilation'
ERROR_QSB_NOT_FOUND = 'qsb-not-found'
ERROR_INVALID_ARGUMENT = 'invalid-argument'

QSB_ARGS = ['--glsl', '150,330,300 es']

# Compiled shaders not used for this long are removed from the cache.
CACHE_MAX_AGE = 30 * 24 * 3600

_UNIFORM_RE = re.compile(r'^\s*uniform\s+(?:(?:lowp|mediump|highp)\s+)?(\w+)\s+(\w+)\s*;.*$', re.MULTILINE)
_VERSION_RE = re.compile(r'^\s*#version\b.*$', re.MULTILINE)
_COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/', re.DOTALL)


class BuildError(Exception):
    def __init__(self, code, log=''):
        super().__init__(log)
        self.code = code
        self.log = log


def hex2vec4(value):
    """
    Convert #rrggbb or #aarrggbb to vec4(r,g,b,a).
    """
    if not re.fullmatch(r'#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})', value):
        raise BuildError(ERROR_INVALID_ARGUMENT, value)
    value = value[1:]
    nums = [int(value[i:i + 2], base=16) / 255 for i in range(0, len(value), 2)]
    if len(nums) < 4:
        nums.insert(0, 1)
    return "vec4(%f,%f,%f,%f)" % tuple(nums[1:] + nums[:1])


def format_value(type_, value):
    if type_ == 'int':
        return f'int({value})'
    if type_ in ('double', 'float'):
        return f'float({value})'
    if type_ == 'bool':
        return f'bool({str(value).lower()})'
    if type_ == 'color':
        return hex2vec4(str(value))
    return str(value)


def substitute_arguments(source, arguments_map):
    """
    Replace the arguments (start with $) used in macro definitions with their values.
    """
    lines = []
    for line in source.splitlines(keepends=True):
        lst = line.split()
        if len(lst) >= 3 and lst[0] == '#define' and lst[2].startswith('$'):
            key = lst[2][1:]
            if key not in arguments_map:
                raise BuildError(ERROR_UNDECLARED_ARGUMENT)
            lst[2] = arguments_map[key]
            line = ' '.join(lst) + '\n'
        lines.append(line)
    return ''.join(lines)


def to_qsb_glsl(source):
    """
    Convert OpenGL style GLSL to the Vulkan style GLSL 440 accepted by qsb:
    all uniforms except samplers are moved into a single uniform block, and
    samplers get explicit bindings.
    """
    uniforms = {'qt_Matrix': 'mat4', 'qt_Opacity': 'float'}
    samplers = {}

    def collect(match):
        type_, name = match.groups()
        if type_.startswith('sampler'):
            samplers.setdefault(name, type_)
        else:
            uniforms.setdefault(name, type_)
        return ''

    body = _VERSION_RE.sub('', _UNIFORM_RE.sub(collect, source))
    head = '#version 440\nlayout(std140, binding = 0) uniform buf {\n'
    head += ''.join(f'    {type_} {name};\n' for name, type_ in uniforms.items())
    head += '};\n'
    for binding, (name, type_) in enumerate(samplers.items(), 1):
        head += f'layout(binding = {binding}) uniform {type_} {name};\n'
    return head + body


def find_qsb():
    for name in ('qsb', 'qsb-qt6', 'qsb6'):
        path = shutil.which(name)
        if path:
            return path
    for qt_dir in ('/usr/lib/qt6', '/usr/lib64/qt6', '/usr/lib/x86_64-linux-gnu/qt6', '/usr/lib/aarch64-linux-gnu/qt6'):
        for sub_dir in ('bin', 'libexec'):
            path = Path(qt_dir) / sub_dir / 'qsb'
            if os.access(path, os.X_OK):
                return str(path)
    raise BuildError(ERROR_QSB_NOT_FOUND)


def compile_shader(source):
    """
    Compile the source with qsb and return the url of the compiled shader.
    Compiled shaders are cached by the hash of their sources.
    """
    source = to_qsb_glsl(source)
    digest = hashlib.sha1((source + repr(QSB_ARGS)).encode()).hexdigest()
    cache_dir.mkdir(parents=True, exist_ok=True)
    frag_path = cache_dir / f'{digest}.frag'
    qsb_path = cache_dir / f'{digest}.frag.qsb'
    if qsb_path.exists():
        # Mark the shader as recently used, see prune_cache.
        qsb_path.touch()
    else:
        frag_path.write_text(source)
        command = [find_qsb(), *QSB_ARGS, '-o', str(qsb_path), str(frag_path)]
        result = subprocess.run(command, capture_output=True, text=True)
        frag_path.unlink()
        if result.returncode != 0:
            qsb_path.unlink(missing_ok=True)
            raise BuildError(ERROR_COMPILATION, result.stdout + result.stderr)
    return qsb_path.as_uri()


def prune_cache():
    if not cache_dir.is_dir():
        return
    expiry = time.time() - CACHE_MAX_AGE
    for path in cache_dir.glob('*.qsb'):
        if path.stat().st_mtime < expiry:
            path.unlink(missing_ok=True)


def build_shader(files, main_file: Path, arguments_map):
    if not main_file.exists():
        return ''
    sources = [read_file(path) for path in files]
    sources[files.index(main_file)] = substitute_arguments(sources[files.index(main_file)], arguments_map)
    return compile_shader(''.join(sources))


def build(effect, argument_values):
    effect_path = Path(effect.path)
    image_shader_path = effect_path if effect_path.is_file() else effect_path / 'image.frag'
    buffer_shader_path = effect_path / 'buffer.frag'

    # Construct a key-value map to store arguments' names and values.
    # Missing values fall back to their defaults.
    arguments = get_effect_list.get_arguments(effect)
    arguments_map = {}
    for index, arg in enumerate(arguments):
        value = argument_values[index] if index < len(argument_values) else arg['default']
        arguments_map[arg['name']] = format_value(arg.get('type'), value)

    # The data channels used by the effect, ignoring the ones only mentioned in comments.
    effect_source = read_file(image_shader_path)
    if buffer_shader_path.exists():
        effect_source += read_file(buffer_shader_path)
    effect_source = _COMMENT_RE.sub('', effect_source)

    texture_path = effect_path / 'texture.png'
    return {
        'image_shader':
        build_shader([
            applet_effect_home / 'hsluv-glsl.fsh',
            applet_effect_home / 'utils.fsh',
            applet_effect_home / 'shadertoy-api-head.fsh',
            image_shader_path,
            applet_effect_home / 'shadertoy-api-foot.fsh',
        ], image_shader_path, arguments_map),
        'buffer_shader':
        build_shader([
            applet_effect_home / 'shadertoy-api-head.fsh',
            buffer_shader_path,
            applet_effect_home / 'shadertoy-api-foot-buffer.fsh',
        ], buffer_shader_path, arguments_map),
        'texture': texture_path.as_uri() if texture_path.exists() else '',
        'enable_iChannel0': 'iChannel0' in effect_source,
        'enable_iChannel1': 'iChannel1' in effect_source,
    }


def main():
    logger.log('argv: %s', sys.argv[1:])
    effect_id, argument_values = json.loads(sys.argv[1])
    logger.log('effect_id: %s', effect_id)
    logger.log('effect_arguments: %s', argument_values)

    try:
        obj = build(get_effect_list.find(effect_id), argument_values or [])
    except BuildError as e:
        obj = {'error_code': e.code, 'log': e.log}
    json.dump(obj, sys.stdout)
    logger.log('obj : %s', json.dumps(obj))
    prune_cache()


if __name__ == '__main__':
    main()
