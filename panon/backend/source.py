import numpy as np
import soundcard as sc


def binary2numpy(data, num_channel):
    data = np.frombuffer(data, 'int16')
    len_data = len(data) // num_channel
    data = data.reshape((len_data, num_channel))
    return data


class PyaudioSource:
    def __init__(self, channel_count, sample_rate, device_index, fps):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.chunk = self.sample_rate // fps
        if device_index is not None:
            device_index = int(device_index)
        self.device_index = device_index

        self.start()

    def read(self, fps=None):
        # Ignores PyAudio exception on overflow.
        if fps is None:
            c = self.chunk
        else:
            c = self.sample_rate // fps
        result = self.stream.read(c, exception_on_overflow=False)
        return binary2numpy(result, self.channel_count)

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
        self.fifo_path = fifo_path
        self.blocksize = sample_rate // fps * channel_count * 2    #int16  44100:16:2

        self.start()

    def read(self, fps=None):
        if fps is None:
            b = self.blocksize
        else:
            b = self.sample_rate // fps * self.channel_count * 2    #int16  44100:16:2
        data = self.stream.read(b)
        if data is None:
            return None
        return binary2numpy(data, self.channel_count)

    def start(self):
        import os
        self.stream = open(self.fifo_path, 'rb')


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
    def __init__(self, channel_count, sample_rate, device_id, fps):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.device_id = device_id
        self.blocksize = self.sample_rate // fps
        self.start()

    def read(self, fps=None):
        if fps is None:
            b = self.blocksize
        else:
            b = self.sample_rate // fps
        data = [stream.record(b) for stream in self.streams]
        data = sum(data) / len(data)
        return data

    def update_smart_device(self, ):
        p = sc.pulseaudio._PulseAudio()
        name = p.server_info['default sink id']

        if name is not None:
            if not self.smart_device_id == name:
                self.smart_device_id = name
                for stream in self.streams:
                    stream.__exit__(None, None, None)

                try:
                    sc.set_name('Panon')
                except (AttributeError, NotImplementedError):
                    pass
                mic = sc.get_microphone(
                    self.smart_device_id + '.monitor',
                    include_loopback=False,
                    exclude_monitors=False,
                )
                stream = mic.recorder(
                    self.sample_rate,
                    self.channel_count,
                    self.blocksize,
                )
                stream.__enter__()
                self.streams = [stream]

    def start(self):
        try:
            sc.set_name('Panon')
        except (AttributeError, NotImplementedError):
            pass

        if self.device_id == 'all':
            mics = sc.all_microphones(exclude_monitors=False)
        elif self.device_id == 'allspeakers':
            mics = [mic for mic in sc.all_microphones(exclude_monitors=False) if mic.id.endswith('.monitor')]
        elif self.device_id == 'allmicrophones':
            mics = [mic for mic in sc.all_microphones(exclude_monitors=True)]
        elif self.device_id == 'default':
            mics = [sc.default_microphone()]
        elif self.device_id == 'smart':
            self.smart_device_id = ''
            mics = [sc.default_microphone()]
        else:
            mics = [sc.get_microphone(
                self.device_id,
                include_loopback=False,
                exclude_monitors=False,
            )]
        self.streams = []
        for mic in mics:
            stream = mic.recorder(
                self.sample_rate,
                self.channel_count,
                self.blocksize,
            )
            stream.__enter__()
            self.streams.append(stream)


if __name__ == '__main__':
    sample = PyaudioSource(2, 44100, None, 60)
    print('Make sure you are playing music when run this script')

    data = sample.read()

    _max = np.max(data)
    _min = np.min(data)
    _sum = np.sum(data)
    print(_max, _min, _sum)

    if _max > 0:
        print('succeeded to catch audio')
    else:
        print('failed to catch audio')
