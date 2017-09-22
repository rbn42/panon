import numpy as np


class Spectrum:
    def __init__(self, sample, buffer_size, decay):
        self.sample = sample
        self.decay = decay
        self.history = np.zeros(buffer_size * 8, dtype='int16')
        self.history_index = 0
        self.buffer_size = buffer_size
        self.min_sample = 10
        self.max_sample = self.min_sample

    def updateHistory(self):

        data = self.sample.read()
        data = np.fromstring(data, 'int16')
        assert len(data) < len(self.history)
        if self.history_index + len(data) > len(self.history):
            self.history[self.history_index:] = data[:len(
                self.history) - self.history_index]
            self.history[:self.history_index + len(data) - len(
                self.history)] = data[len(self.history) - self.history_index:]
            self.history_index -= len(self.history)
        else:
            self.history[self.history_index:self.history_index +
                         len(data)] = data
        self.history_index += len(data)

        data_history = np.concatenate([
            self.history[self.history_index:],
            self.history[:self.history_index],
        ])
        return data_history

    def getData(self):
        data_history = self.updateHistory()

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

            fft = np.absolute(np.fft.rfft(d, n=size))
            end = min(len(fft) // 2, end)
            fft_freq.insert(0, fft[start:end])
            fft_freq.append(fft[len(fft) - end:len(fft) - start])

        # higher resolution and latency for lower frequency
        fun(110, 150, 2)
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
        return fft / self.max_sample ** (1 / exp)
