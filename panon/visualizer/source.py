import pyaudio


class Source:
    def __init__(self,  channel_count, sample_rate, dtype='int16'):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.dtype = {
            'int16': pyaudio.paInt16,
            'float32': pyaudio.paFloat32,
            'int32': pyaudio.paInt32,
        }[dtype]

        self.start()

    def read(self):
        size = self.stream.get_read_available()
        return self.stream.read(size)

    def stop(self):
        self.stream.close()

    def start(self):
        p = pyaudio.PyAudio()
        self.stream = p.open(format=self.dtype,
                             channels=self.channel_count,
                             rate=self.sample_rate,
                             input=True)
