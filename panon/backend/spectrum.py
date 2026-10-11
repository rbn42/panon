import numpy as np

NUM_CHANNEL = 2
SAMPLE_RATE = 44100
HISTORY_LENGTH = 32 * 8

# Frequency bands of each bass resolution level (see ConfigBackend.qml), from high to low frequency.
# Lower frequencies use longer windows, which gives a higher resolution but a higher latency.
# (from, to, latency, weight_from, weight_to): from/to are indices of a 60Hz fft, latency is the
# window size relative to the fft size, and the weights reduce the bass when reduceBass is enabled.
BANDS = {
    1: [
        (110, 150, 2, None, None),    # 6600-9000Hz
        (80, 110, 3, None, None),    # 4800-6600Hz
        (50, 80, 4, None, None),    # 3000-4800Hz
        (30, 50, 5, 1 / 1.2, 1),    # 1800-3000Hz
        (10, 30, 6, 1 / 1.5, 1 / 1.2),    # 600-1800Hz
        (0, 10, 8, 1 / 3, 1 / 1.5),    # 0-600Hz
    ],
    2: [
        (30, 50, 4, 1 / 1.2, 1),    # 1800-3000Hz
        (10, 30, 8, 1 / 1.5, 1 / 1.2),    # 600-1800Hz
        (0, 10, 12, 1 / 3, 1 / 1.5),    # 0-600Hz
    ],
    3: [
        (10, 30, 12, 1 / 1.5, 1 / 1.2),    # 600-1800Hz
        (0, 10, 16, 1 / 3, 1 / 1.5),    # 0-600Hz
    ],
    4: [
        (0, 30, 6, 1 / 3, 1 / 1.2),    # 0-1800Hz
    ],
    5: [
        (5, 30, 6, 1 / 3, 1 / 1.2),    # 300-1800Hz
    ],
    6: [
        (0, 10, 16, 1 / 3, 1 / 1.5),    # 0-600Hz
    ],
}


class Spectrum:
    def __init__(self, fft_size=SAMPLE_RATE // 60):
        self.fft_size = fft_size

        self.history = np.zeros((self.fft_size * HISTORY_LENGTH, NUM_CHANNEL), dtype='int16')
        self.history_index = 0

    def updateHistory(self, data):
        len_history, _ = self.history.shape

        len_data, _ = data.shape
        if len_data > 0:
            index = self.history_index

            if index + len_data > len_history:
                self.history[index:] = data[:len_history - index]
                self.history[:index + len_data - len_history] = data[len_history - index:]
                self.history_index -= len_history
            else:
                self.history[index:index + len_data] = data
            self.history_index += len_data

        return np.concatenate([
            self.history[self.history_index:],
            self.history[:self.history_index],
        ], axis=0)

    def band(self, data_history, freq_from, freq_to, latency, weight_from=None, weight_to=None):
        size = int(self.fft_size * latency)
        fft = np.absolute(np.fft.rfft(data_history[-size:], axis=0))
        result = fft[int(freq_from * latency):int(freq_to * latency)]
        if weight_from is not None:
            size_output, _ = result.shape
            weights = np.arange(weight_from, weight_to, (weight_to - weight_from) / size_output)[:size_output]
            result = result * weights[:, np.newaxis]
        return result

    def computeSpectrum(self, data_history, bassResolutionLevel, reduceBass=False):
        if np.max(data_history) == 0:
            return None

        if bassResolutionLevel not in BANDS:
            return np.absolute(np.fft.rfft(data_history[-self.fft_size:], axis=0))    # 0-22050Hz

        bands = []
        for freq_from, freq_to, latency, weight_from, weight_to in reversed(BANDS[bassResolutionLevel]):
            if not reduceBass:
                weight_from = weight_to = None
            bands.append(self.band(data_history, freq_from, freq_to, latency, weight_from, weight_to))
        return np.concatenate(bands, axis=0)
