import glob
import sys
import os
from helper import config_effect_home, applet_effect_home


def _get_list(root):
    l = glob.glob(os.path.join(root, '*/')) + glob.glob(os.path.join(root, '*.frag'))
    return [n[len(root):] for n in l]


def get_list():
    l1 = _get_list(applet_effect_home)
    l2 = _get_list(config_effect_home)
    l2 = [n + ' ' for n in l2]
    l = l1 + l2
    l.sort()
    return l


if __name__ == '__main__':
    import json
    json.dump(get_list(), sys.stdout)
