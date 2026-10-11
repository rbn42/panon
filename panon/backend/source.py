import contextlib

import numpy as np

from .. import logger


def binary2numpy(data, num_channel):
    data = np.frombuffer(data, 'int16')
    len_data = len(data) // num_channel
    return data[:len_data * num_channel].reshape((len_data, num_channel))


class Source:
    def __init__(self, channel_count, sample_rate, fps):
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.fps = fps

    def frames(self, fps=None):
        """
        The number of frames to read for one update at the given fps.
        """
        return self.sample_rate // (fps or self.fps)

    def update_device(self):
        """
        Called while audio is unavailable, so that sources can follow device changes.
        """


class PyaudioSource(Source):
    def __init__(self, channel_count, sample_rate, fps):
        super().__init__(channel_count, sample_rate, fps)
        import pyaudio
        self.stream = pyaudio.PyAudio().open(
            format=pyaudio.paInt16,
            channels=self.channel_count,
            rate=self.sample_rate,
            input=True,
            frames_per_buffer=self.frames(),
        )

    def read(self, fps=None):
        # Ignores PyAudio exception on overflow.
        result = self.stream.read(self.frames(fps), exception_on_overflow=False)
        return binary2numpy(result, self.channel_count)


class FifoSource(Source):
    def __init__(self, channel_count, sample_rate, fifo_path, fps):
        super().__init__(channel_count, sample_rate, fps)
        self.fifo_path = fifo_path
        self.stream = open(self.fifo_path, 'rb')

    def read(self, fps=None):
        data = self.stream.read(self.frames(fps) * self.channel_count * 2)    # int16
        if not data:
            # The writer has closed the fifo. Reopening blocks until a new writer appears.
            self.stream.close()
            self.stream = open(self.fifo_path, 'rb')
        return binary2numpy(data, self.channel_count)


class SoundCardSource(Source):
    def __init__(self, channel_count, sample_rate, device_id, fps):
        super().__init__(channel_count, sample_rate, fps)
        import soundcard
        self.sc = soundcard
        self.sc.set_name('Panon')
        self.device_id = device_id
        self.monitored_speaker_id = None
        self.recorders = contextlib.ExitStack()
        self.streams = []
        self.open(self.get_microphones())

    def read(self, fps=None):
        data = [stream.record(self.frames(fps)) for stream in self.streams]
        return sum(data) / len(data)

    def get_microphones(self):
        sc = self.sc
        if self.device_id == 'all':
            return sc.all_microphones(include_loopback=True)
        if self.device_id == 'allspeakers':
            return [mic for mic in sc.all_microphones(include_loopback=True) if mic.isloopback]
        if self.device_id == 'allmicrophones':
            return sc.all_microphones(include_loopback=False)
        if self.device_id == 'default':
            return [sc.default_microphone()]
        if self.device_id == 'smart':
            # Monitor of the current default speaker
            self.monitored_speaker_id = sc.default_speaker().id
            return [sc.get_microphone(self.monitored_speaker_id + '.monitor', include_loopback=True)]
        return [sc.get_microphone(self.device_id, include_loopback=True)]

    def open(self, mics):
        self.recorders.close()
        self.streams = [
            self.recorders.enter_context(mic.recorder(self.sample_rate, self.channel_count, self.frames()))
            for mic in mics
        ]

    def update_device(self):
        if self.device_id != 'smart':
            return
        speaker_id = self.sc.default_speaker().id
        if speaker_id != self.monitored_speaker_id:
            logger.log('update smart device: %s', speaker_id)
            self.open(self.get_microphones())
