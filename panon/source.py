import pyaudio


class Source:
    def __init__(self, channel_count, sample_rate):
        self.channel_count = channel_count
        self.sample_rate = sample_rate

        self.start()

    def readlatest(self, max_size=1000000):
        size = self.stream.get_read_available()
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
        self.stream = p.open(format=pyaudio.paInt16, channels=self.channel_count, rate=self.sample_rate, input=True)
