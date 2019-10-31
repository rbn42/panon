import numpy as np


class Decay:
    def __init__(self):
        self.global_decay = 0.01
        self.local_decay = 0.003

        self.min_sample = 10
        self.max_sample = self.min_sample

        self.local_max = None

    def process(self, fft):

        exp = 2
        retain = (1 - self.global_decay)**exp
        global_decay = 1 - retain

        vol = self.min_sample + np.mean(fft**exp)
        self.max_sample = self.max_sample * retain + vol * global_decay
        global_max = self.max_sample**(1 / exp)

        if self.local_max is None:
            self.local_max = fft
        else:
            self.local_max = np.max([
                fft,
                self.local_max**(1 - self.local_decay),
            ], axis=0)

        return fft / global_max, self.local_max / global_max
