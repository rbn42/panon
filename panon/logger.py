import logging

_logger=None
try:
    from systemd.journal import JournalHandler

    _logger = logging.getLogger('demo')
    _logger.addHandler(JournalHandler())
    _logger.setLevel(logging.DEBUG)
except:
    pass

def log(*a):
    if _logger is not None:
        _logger.debug(*a)
