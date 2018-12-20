import numpy as np
from .source import Source2 as Source


class Spectrum:
    def __init__(
            self,
            fps,
            decay,
            channel_count=2,
            sample_rate=44100,
    ):
        self.sample = Source(channel_count, sample_rate)
        self.decay = decay

        buffer_size = sample_rate // fps
        self.buffer_size = buffer_size

        self.history = np.zeros((channel_count, buffer_size * 8), dtype='int16')
        self.history_index = 0

        self.min_sample = 10
        self.max_sample = self.min_sample

    def stop(self):
        self.sample.stop()

    def start(self):
        self.sample.start()

    def updateHistory(self):

        data = self.sample.read()
        data = np.fromstring(data, 'int16')

        len_data = len(data) // self.history.shape[0]

        len_history = self.history.shape[1]
        index = self.history_index
        assert len_data < len_history

        data = data.reshape((len_data, self.history.shape[0]))
        data = np.rollaxis(data, 1)

        if index + len_data > len_history:
            self.history[:, index:] = data[:, :len_history - index]
            self.history[:, :index + len_data - len_history] = data[:, len_history - index:]
            self.history_index -= len_history
        else:
            self.history[:, index:index + len_data] = data
        self.history_index += len_data

        data_history = np.concatenate([
            self.history[:, self.history_index:],
            self.history[:, :self.history_index],
        ], axis=1)

        return data_history

    def getData(self):
        data_history = self.updateHistory()

        fft_freq = []

        def fun(start, end, rel):
            size = self.buffer_size
            start = int(start * rel)
            end = int(end * rel)
            size = int(size * rel)
            d = data_history[:, -size:]

            fft = np.absolute(np.fft.rfft(d, n=size))
            fft_freq.insert(0, fft[:, start:end])

        # higher resolution and latency for lower frequency
        fun(110, 150, 2)
        fun(80, 110, 3)
        fun(50, 80, 4)
        fun(30, 50, 5)
        fun(10, 30, 6)
        fun(0, 10, 8)

        fft = np.concatenate(fft_freq, axis=1)

        exp = 2
        retain = (1 - self.decay)**exp
        decay = 1 - retain

        vol = self.min_sample + np.mean(fft**exp)
        self.max_sample = self.max_sample * retain + vol * decay
        return fft / self.max_sample**(1 / exp)
