"""
This module defines the data structure of an effect,
and the way to generate unique effect identities.
The data structure is used by ConfigEffect.qml and
build_shader_source.py.
"""
import collections
import json
import sys
from pathlib import Path

from .helper import effect_dirs, read_file

# The data structure of an effect
Effect = collections.namedtuple('Effect', 'name id path')


def _get_shaders(root: Path, root_id):
    if not root.is_dir():
        return
    for path in root.iterdir():
        if path.suffix == '.frag' or any(path.glob('*.frag')):
            yield Effect(
                path.name,
                # generate unique effect identities
                f'{root_id}.' + path.name.replace(' ', '_').replace('"', '__').replace("'", '___').replace('$', '____'),
                str(path.absolute()),
            )


def get_list():
    """
    Returns an array of all available visual effects.
    """
    return sorted(effect for root_id, root in enumerate(effect_dirs) for effect in _get_shaders(root, root_id))


def find(effect_id):
    """
    Returns the effect with the given identity, or the default effect.
    """
    effects = get_list()
    for effect in effects:
        if effect.id == effect_id:
            return effect
    for effect in effects:
        if effect.name == 'default':
            return effect


def get_arguments(effect):
    meta_file = Path(effect.path) / 'meta.json'
    if not meta_file.is_file():
        return []
    return json.loads(meta_file.read_bytes())['arguments']


def get_hint(effect):
    hint_file = Path(effect.path) / 'hint.html'
    return read_file(hint_file) if hint_file.is_file() else ''


if __name__ == '__main__':
    json.dump([{
        'name': effect.name,
        'id': effect.id,
        'hint': get_hint(effect),
        'arguments': get_arguments(effect),
    } for effect in get_list()], sys.stdout)
