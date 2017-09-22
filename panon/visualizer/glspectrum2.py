import numpy as np
import ModernGL
from .. import glsl
from .source import Source


class GLSpectrum:
    def __init__(self, sample, buffer_size, decay):
        import pyaudio
        self.sample = Source(2,3000,'float32')
        sample.start()

        self.decay = decay
        self.buffer_size = buffer_size
        self.min_sample = 10
        self.max_sample = self.min_sample

        self.history_size = 1024 
        self.history_index = 0

        ctx = ModernGL.create_standalone_context()
        compute_shader = ctx.compute_shader(glsl.load('spectrum.glsl'))

        empty = b'\00' * self.history_size * 4
        buf_history = ctx.buffer(empty)
        empty = b'\00' * (1024 // 2) * 4
        buf_output = ctx.buffer(empty)
        buf_history.bind_to_storage_buffer(1)
        buf_output.bind_to_storage_buffer(2)

        self.compute_shader = compute_shader
        self.ctx = ctx
        self.buf_history = buf_history
        self.buf_output = buf_output

    def updateHistory(self):
        data = self.sample.read()
        self.history_index = self.load_offset(
            data, self.buf_history,
            self.history_index * 4,
            len(data), self.history_size * 4) // 4

    def load_offset(self, data, history,
                    index, data_size, history_size):
        if data_size + index < history_size:
            history.write(data, offset=index)
            return index + data_size
        elif data_size > history_size:
            history.write(data[-history_size:])
            return 0
        else:
            history.write(data[:history_size - index], offset=index)
            history.write(data[history_size - index:], offset=0)
            return index + data_size - history_size

    def compute(self, rel=1):
        self.compute_shader.uniforms['history_index'].value = self.history_index
        self.compute_shader.uniforms['rel'].value = rel
        self.compute_shader.run()
        return self.buf_output.read()

    def getData(self):
        self.updateHistory()

        fft = self.compute()
        fft = np.frombuffer(fft, dtype='float32')

        exp = 2
        retain = (1 - self.decay)**exp
        decay = 1 - retain

        vol = self.min_sample + np.mean(fft ** exp)
        self.max_sample = self.max_sample * retain + vol * decay
        bins = fft / self.max_sample ** (1 / exp)
        return bins

    def destroy(self):
        self.ctx.release()
