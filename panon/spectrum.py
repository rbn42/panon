import numpy as np

NUM_CHANNEL = 2
HISTORY_LENGTH = 32


class Spectrum:
    def __init__(
            self,
            source,
            fft_size=44100 // 60,
    ):
        self.sample = source
        self.fft_size = fft_size

        self.history = np.zeros((NUM_CHANNEL, self.fft_size * HISTORY_LENGTH), dtype='int16')
        self.history_index = 0

    def updateHistory(self, expect_buffer_size):

        len_history = self.history.shape[1]
        num_channel = self.history.shape[0]

        data = self.sample.readlatest(expect_buffer_size, len_history * num_channel)

        if data is not None:
            data = np.frombuffer(data, 'int16')

            len_data = len(data) // num_channel

            index = self.history_index
            #assert len_data < len_history

            data = data.reshape((len_data, num_channel))
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

    def fun(
            self,
            data_history,
            freq_from,
            freq_to,
            latency,
            reduceBass=False,
            weight_from=None,
            weight_to=None,
    ):
        size = self.fft_size
        freq_from = int(freq_from * latency)
        freq_to = int(freq_to * latency)
        size = int(size * latency)
        d = data_history[:, -size:]

        fft = np.absolute(np.fft.rfft(d, n=size))
        result = fft[:, freq_from:freq_to]
        if reduceBass and weight_from:
            size_output = result.shape[1]
            result = result * np.arange(weight_from, weight_to, (weight_to - weight_from) / size_output)[:size_output]
        debug = False
        if debug:
            #add splitters
            result = np.concatenate([result, np.zeros((2, 8))], axis=1)
            return result
        else:
            return result

    def getData(
            self,
            data_history,
            bassResolutionLevel,
            reduceBass=False,
            **args,
    ):
        if np.max(data_history) == 0:
            return None

        if bassResolutionLevel == 0:
            fft = np.absolute(np.fft.rfft(data_history[:, -self.fft_size:], n=self.fft_size))
            return fft
        elif bassResolutionLevel == 1:
            # higher resolution and latency for lower frequency
            fft_freq = [
            #self.fun(data_history, 250, 4000, 0.25),    # 25px
            #self.fun(data_history, 200, 250, 0.5),    # 25px
            #self.fun(data_history, 150, 200, 1),    # 50px
                self.fun(data_history, 110, 150, 2),    #   6600-9000Hz 80px
                self.fun(data_history, 80, 110, 3),    #   4800-6600Hz 90px
                self.fun(data_history, 50, 80, 4),    #   3000-4800Hz 120px
                self.fun(data_history, 30, 50, 5, reduceBass, 1 / 1.2, 1),    #   1800-3000Hz 100px
                self.fun(data_history, 10, 30, 6, reduceBass, 1 / 1.5, 1 / 1.2),    #   600-1800Hz  120px  
                self.fun(data_history, 0, 10, 8, reduceBass, 1 / 3, 1 / 1.5),    #   0-600Hz     80px 
            ]
        elif bassResolutionLevel == 2:
            fft_freq = [
                self.fun(data_history, 10, 30, 12, reduceBass, 1 / 1.5, 1 / 1.2),    #   600-1800Hz  120px
                self.fun(data_history, 0, 10, 16, reduceBass, 1 / 3, 1 / 1.5),    #   0-600Hz     80px
            ]

        fft_freq.reverse()
        fft = np.concatenate(fft_freq, axis=1)

        return fft
