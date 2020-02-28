def canImportAubio():
    import importlib
    return importlib.find_loader('aubio') is not None


class BeatsDetector:
    def __init__(self, channels, samplerate, cfg_fps):

        hop_s = samplerate // cfg_fps * channels    # hop size
        win_s = hop_s * 2    # fft size

        import aubio
        # create aubio tempo detection
        self.a_tempo = aubio.tempo("default", win_s, hop_s, samplerate)
        self.hop_s = hop_s

    def isBeat(self, samples):
        return float(self.a_tempo(samples.reshape((self.hop_s, )))[0])


if __name__ == '__main__':
    channels = 2
    samplerate = 44100
    fps = 60
    from . import source
    spectrum_source = source.SoundCardSource(channels, samplerate, 'default', fps)
    beatsDetector = BeatsDetector(channels, samplerate, fps)

    while True:
        data = spectrum_source.read()
        b = beatsDetector.isBeat(data)
        print(b)
