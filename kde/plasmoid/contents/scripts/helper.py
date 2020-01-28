import sys
import os
from pathlib import Path


_data_home = os.environ.get('XDG_DATA_HOME', None) or Path.home() / '.local' / 'share'

effect_dirs = [
    _data_home / 'panon',
    Path.home() / '.config' / 'panon',  # legacy
    Path(sys.argv[0]).parent.parent / 'shaders'
]


def read_file(path: Path):
    return path.open('rb').read().decode(errors='ignore')


def read_file_lines(path: Path):
    for line in path.open('rb'):
        yield line.decode(errors='ignore')
