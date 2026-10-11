import numpy as np


EXP = 2
# The share of the previous volume kept in each update.
RETAIN = (1 - 0.01)**EXP
MIN_SAMPLE = 10


class Decay:
    """
    Normalizes the spectrum by a slowly following average of its volume.
    """

    def __init__(self):
        self.max_sample = MIN_SAMPLE

    def process(self, fft):
        if fft is None:
            return None

        global_max = self.max_sample**(1 / EXP)

        vol = MIN_SAMPLE + np.mean(fft**EXP)
        self.max_sample = self.max_sample * RETAIN + vol * (1 - RETAIN)

        return fft / global_max
