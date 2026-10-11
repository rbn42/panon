import os
from pathlib import Path

_data_home = os.environ.get('XDG_DATA_HOME') or Path.home() / '.local' / 'share'
_cache_home = os.environ.get('XDG_CACHE_HOME') or Path.home() / '.cache'

# The shaders shipped with the applet: <applet>/contents/shaders
applet_effect_home = Path(__file__).absolute().parents[3] / 'shaders'

effect_dirs = [
    Path(_data_home) / 'panon',
    Path.home() / '.config' / 'panon',    # legacy
    applet_effect_home,
]

cache_dir = Path(_cache_home) / 'panon'


def read_file(path: Path):
    return path.read_text(encoding='utf-8', errors='ignore')
