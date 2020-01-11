import sys
import os
config_effect_home = os.path.expanduser('~/.config/panon/')
applet_effect_home = os.path.join(os.path.split(sys.argv[0])[0], '../shaders/')


def read_file(path):
    return open(path, 'rb').read().decode(errors='ignore')


def read_file_lines(path):
    for line in open(path, 'rb'):
        yield line.decode(errors='ignore')
