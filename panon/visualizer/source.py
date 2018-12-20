import pyaudio

from ..config import visualizer_fifo


class Source:
    def __init__(self, channel_count, sample_rate):
        self.channel_count = channel_count
        self.sample_rate = sample_rate

        self.start()

    def read(self):
        size = self.stream.get_read_available()
        return self.stream.read(size)

    def stop(self):
        self.stream.close()

    def start(self):
        p = pyaudio.PyAudio()
        self.stream = p.open(format=pyaudio.paInt16, channels=self.channel_count, rate=self.sample_rate, input=True)


FPS = 25


class Source2:
    def __init__(self, channel_count, sample_rate):
        self.channel_count = channel_count
        self.sample_rate = sample_rate

        self.start()

    def read(self):
        return self.stream.read(self.sample_rate // FPS * self.channel_count)

    def stop(self):
        self.stream.close()

    def start(self):
        self.stream = open(visualizer_fifo, 'rb')
        # nonblock
        fd = self.stream.fileno()
        flag = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, flag | os.O_NONBLOCK)
        flag = fcntl.fcntl(fd, fcntl.F_GETFL)


import fcntl
import os
