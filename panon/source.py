import numpy as np


def binary2numpy(data, num_channel):
    data = np.frombuffer(data, 'int16')
    len_data = len(data) // num_channel
    data = data.reshape((len_data, num_channel))
    return data


class PyaudioSource:
    def __init__(self, channel_count, sample_rate, device_index, chunk=1024):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.chunk = chunk
        if device_index is not None:
            device_index = int(device_index)
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
        return binary2numpy(result, self.channel_count)

    def stop(self):
        self.stream.close()

    def start(self):
        import pyaudio
        p = pyaudio.PyAudio()
        self.stream = p.open(
            format=pyaudio.paInt16,
            channels=self.channel_count,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.chunk,
            input_device_index=self.device_index,
        )


class FifoSource:
    def __init__(self, channel_count, sample_rate, fifo_path, fps):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.fps = fps
        self.fifo_path = fifo_path

        self.start()

    def readlatest(self, expect_size, max_size=1000000):
        data = self.stream.read(self.sample_rate // self.fps * self.channel_count)
        if data is None:
            return None
        return binary2numpy(data, self.channel_count)

    def stop(self):
        self.stream.close()

    def start(self):
        import fcntl
        import os
        self.stream = open(self.fifo_path, 'rb')
        # nonblock
        fd = self.stream.fileno()
        flag = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, flag | os.O_NONBLOCK)
        flag = fcntl.fcntl(fd, fcntl.F_GETFL)


class SounddeviceSource:
    def __init__(self, channel_count, sample_rate, device_index):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        if device_index is not None:
            device_index = int(device_index)
        self.device_index = device_index

        self.start()

    def readlatest(self, expect_size, max_size=1000000):
        size = self.stream.read_available
        data, _ = self.stream.read(size)
        return data

    def stop(self):
        self.stream.close()

    def start(self):
        import sounddevice as sd
        self.stream = sd.InputStream(
            latency='low',
            samplerate=self.sample_rate,
            device=self.device_index,
            channels=self.channel_count,
            dtype='int16',
        )
        self.stream.start()


class SoundCardSource:
    def __init__(self, channel_count, sample_rate, device_id, blocksize):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.device_id = device_id
        self.blocksize = blocksize

        self.start()

    def readlatest(self, expect_size, max_size=1000000):
        data = self.stream.record(expect_size)
        data = np.asarray(data * (2**16), dtype='int16')
        return data

    def stop(self):
        self.stream.close()

    def start(self):
        from . import pulseaudio as sc
        if self.device_id is None:
            mic = sc.default_microphone()
        else:
            mic = sc.get_microphone(
                self.device_id,
                include_loopback=False,
                exclude_monitors=False,
            )
        self.stream = mic.recorder(
            self.sample_rate,
            self.channel_count,
            self.blocksize,
        )
        self.stream.__enter__()


if __name__ == '__main__':
    import numpy as np
    import time
    sample = PyaudioSource(2, 44100, None)
    print('Make sure you are playing music when run this script')

    time.sleep(2)

    data = sample.readlatest(1024 * 16)
    data = np.frombuffer(data, 'int16')

    _max = np.max(data)
    _min = np.min(data)
    _sum = np.sum(data)
    print(_max, _min, _sum)
    if _max > 0:
        print('succeeded to catch audio')
    else:
        print('failed to catch audio')
