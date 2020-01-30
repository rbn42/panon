"""
This module defines the data structure of an effect,
and the way to generate unique effect identities.
The data structure is used by ConfigEffect.qml and 
build_shader_source.py.
"""
import sys
from pathlib import Path
from helper import effect_dirs
import collections

# The data structure of an effect
Effect = collections.namedtuple('Effect', 'name id path')


def _get_shaders(root: Path, root_id):
    if not root.is_dir():
        return
    for _file in root.iterdir():
        if _file.suffix == '.frag' or any(_file.glob('*.frag')):
            yield Effect(
                _file.name,
            # generate unique effect identities
                str(root_id) + '.' + _file.name.replace(' ', '_').replace('"', '__').replace("'", '___').replace("$", '____'),
                str(_file.absolute()),
            )


def get_list():
    """
    Returns an array of all available visual effects.
    """
    return sorted([effect for effect_dir_id, effect_dir in enumerate(effect_dirs) for effect in _get_shaders(effect_dir, effect_dir_id)])


if __name__ == '__main__':
    import json
    json.dump([effect._asdict() for effect in get_list()], sys.stdout)
