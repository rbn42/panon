import numpy as np


class GLSpectrum:
    def __init__(self, sample, buffer_size, decay):
        self.sample = sample
        self.decay = decay
        self.history = [[]] * 8
        self.buffer_size = buffer_size
        self.min_sample = 10
        self.max_sample = self.min_sample

        from .glfft import GLFFT
        self.glfft = GLFFT()

    def getData(self):
        data = self.sample.read()
        data = np.fromstring(data, 'int16')

        self.history.append(data)
        if sum([len(d) for d in self.history[1:]]) > self.buffer_size * 8:
            self.history.pop(0)

        data_history = np.concatenate(self.history)
        fft_freq = []

        def fun(start, end,  rel):
            size = self.buffer_size
            if rel > 20:
                start, end = int(start), int(end)
                rel = int(rel)
                d = data_history[-size * rel:].reshape((rel, size))
                d = np.mean(d, axis=0)
            else:
                start = int(start * rel)
                end = int(end * rel)
                size = int(size * rel)
                d = data_history[-size:]

            fft = self.glfft.compute(d.astype('float32').tobytes())
            fft = np.frombuffer(fft, dtype='float32')
            end = min(len(fft) // 2, end)
            fft_freq.insert(0, fft[start:end])
            fft_freq.append(fft[len(fft) - end:len(fft) - start])
        # higher resolution and latency for lower frequency

        sections = 8
        r = 0.6
        rels = 8 * r**np.arange(sections)
        start = 0
        sections = []
        for rel, freq_width in zip(rels, len(data) * 1 / rels / sum(1 / rels) // 4):
            if rel > 2:
                freq_width *= rel
                pass
            sections.append((start, start + freq_width, rel))
            start += freq_width
        sections.reverse()
        for start, end, rel in sections:
            #fun(start, end, rel)
            pass

        fun(110, 150, 2)
#        fun(0, 110, 3)
        fun(80, 110, 3)
        fun(50, 80, 4)
        fun(30, 50, 5)
        fun(10, 30, 6)
        fun(0, 10, 8)

        fft = np.concatenate(fft_freq)

        exp = 2
        retain = (1 - self.decay)**exp
        decay = 1 - retain

        vol = self.min_sample + np.mean(fft ** exp)
        self.max_sample = self.max_sample * retain + vol * decay
        bins = fft / self.max_sample ** (1 / exp)
        return bins
