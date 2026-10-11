"""
panon client

Reads audio data, computes the spectrum and sends both to the
applet's websocket server as data URIs of images.
"""
import argparse
import asyncio
import json
import sys

import numpy as np
import websockets

from . import source
from .convertor import Numpy2Str
from .decay import Decay
from .spectrum import NUM_CHANNEL, SAMPLE_RATE, Spectrum
from .. import logger


def compress(values, knee=0.6):
    """
    Map values to [0, 1). Values below the knee are kept, larger values approach 1
    asymptotically, so that loud peaks keep their shape instead of being cut off.
    """
    over = np.maximum(values - knee, 0) / (1 - knee)
    return np.minimum(values, knee) + (1 - knee) * over / (1 + over)


def parse_args():
    parser = argparse.ArgumentParser(prog='panon client')
    parser.add_argument('url')
    parser.add_argument('--backend', choices=['pyaudio', 'soundcard', 'fifo'], default='pyaudio')
    parser.add_argument('--device', default='default', help='PulseAudio device id (soundcard back-end)')
    parser.add_argument('--fifo-path', help='fifo back-end')
    parser.add_argument('--fps', type=int, default=30)
    parser.add_argument('--reduce-bass', action='store_true')
    parser.add_argument('--bass-resolution-level', type=int, default=1)
    parser.add_argument('--enable-wave-data', action='store_true')
    parser.add_argument('--enable-spectrum-data', action='store_true')
    return parser.parse_args()


def create_source(args):
    if args.backend == 'pyaudio':
        return source.PyaudioSource(NUM_CHANNEL, SAMPLE_RATE, args.fps)
    if args.backend == 'fifo':
        return source.FifoSource(NUM_CHANNEL, SAMPLE_RATE, args.fifo_path, args.fps)
    return source.SoundCardSource(NUM_CHANNEL, SAMPLE_RATE, args.device, args.fps)


def create_beats_detector(args):
    # aubio requires float samples, which are only provided by the soundcard back-end.
    if args.backend != 'soundcard':
        return None
    from .beat import BeatsDetector
    try:
        return BeatsDetector(NUM_CHANNEL, SAMPLE_RATE, args.fps)
    except ImportError:    # aubio is optional
        return None


async def mainloop(args, spectrum_source, beats_detector):
    async with websockets.connect(args.url) as websocket:
        spec = Spectrum()
        decay = Decay()
        n2s = Numpy2Str()

        audio_available = True
        logger.log('loop')
        while True:
            is_beat = False
            if audio_available:
                latest_wave_data = spectrum_source.read()
                if beats_detector is not None:
                    is_beat = beats_detector.isBeat(latest_wave_data)
            else:
                # Set fps to 2 to lower CPU usage, when audio is unavailable.
                latest_wave_data = spectrum_source.read(fps=2)
                spectrum_source.update_device()

            if latest_wave_data.dtype.type is np.float32:
                latest_wave_data = np.clip(latest_wave_data * 32767, -32768, 32767).astype('int16')

            wave_hist = spec.updateHistory(latest_wave_data)
            data = spec.computeSpectrum(wave_hist, args.bass_resolution_level, args.reduce_bass)
            spectrum_data = decay.process(data)

            audio_available = spectrum_data is not None
            if not audio_available:
                await websocket.send('')
                continue

            obj = {'beat': is_beat}
            if args.enable_wave_data:
                wave_data = latest_wave_data.astype('float')
                wave_max = max(np.max(np.abs(wave_data)), 1)
                wave_data = (wave_data + wave_max) / wave_max / 2 * 255
                obj['wave'] = n2s.convert(wave_data)
            if args.enable_spectrum_data:
                spectrum_data = compress(spectrum_data[1:] / 3.0) * 255
                spectrum_data_m = n2s.convert(spectrum_data)
                # When only spectrum data is enabled, send raw data to reduce cpu usage.
                if not args.enable_wave_data:
                    await websocket.send(spectrum_data_m)
                    continue
                obj['spectrum'] = spectrum_data_m

            await websocket.send(json.dumps(obj))


def main():
    logger.log('argv: %s', sys.argv[1:])
    args = parse_args()
    try:
        asyncio.run(mainloop(args, create_source(args), create_beats_detector(args)))
    except websockets.ConnectionClosed:
        # The applet has been closed or reloaded.
        pass


if __name__ == '__main__':
    main()
