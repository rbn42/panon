import sys
from pathlib import Path
from helper import effect_dirs


def _get_shaders(root: Path):
    if not root.is_dir():
        return
    for file in root.iterdir():
        if file.suffix == '.frag' or any(file.glob('*.frag')):
            yield file.name


def get_list():
    return sorted(
        effect_name
        for effect_dir in effect_dirs
        for effect_name in _get_shaders(effect_dir)
    )


if __name__ == '__main__':
    import json
    json.dump(get_list(), sys.stdout)
