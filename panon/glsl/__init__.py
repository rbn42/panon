import os.path


def load(filename):
    path = os.path.dirname(__file__)
    path = os.path.join(path, filename)
    return open(path).read()
