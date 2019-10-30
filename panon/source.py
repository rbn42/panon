import pyaudio


class Source:
    def __init__(self, channel_count, sample_rate, device_index, chunk=1024):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.chunk = chunk
        self.device_index = device_index

        self.start()

    def readlatest(self, expect_size, max_size=1000000):
        size = self.stream.get_read_available()
        #stream.get_read_available() may not work properly in some situations.
        #https://github.com/rbn42/panon/issues/4
        if size < 1:
            #Fall back to normal mode.
            result = self.stream.read(expect_size)[-max_size:]
        else:
            #Read latest data.
            result = b''
            while size > 0:
                result += self.stream.read(size)
                result = result[-max_size:]
                size = self.stream.get_read_available()
        return result

    def stop(self):
        self.stream.close()

    def start(self):
        p = pyaudio.PyAudio()
        self.stream = p.open(
            format=pyaudio.paInt16,
            channels=self.channel_count,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.chunk,
            input_device_index=self.device_index,
        )


if __name__ == '__main__':
    import numpy as np
    import time

    sample = Source(2, 44100)

    time.sleep(2)

    data = sample.readlatest(1024 * 16)
    data = np.frombuffer(data, 'int16')

    _max = np.max(data)
    _min = np.min(data)
    _sum = np.sum(data)
    print(_max, _min, _sum)
    if _max > 0:
        print('success')
    else:
        print('fail')
