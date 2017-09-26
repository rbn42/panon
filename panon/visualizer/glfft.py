from .. import glsl
import ModernGL


class GLFFT:
    def __init__(self):
        ctx = ModernGL.create_standalone_context()
        compute_shader = ctx.compute_shader(glsl.load('fft.glsl'))
        size = 1024 * 4
        empty = b'\00' * size * 4
        buf1 = ctx.buffer(empty)
        empty = b'\00' * size * 4
        buf2 = ctx.buffer(empty)
        buf1.bind_to_storage_buffer(1)
        buf2.bind_to_storage_buffer(2)
        #compute_shader.uniforms['mul'].value = 100.0

        self.compute_shader = compute_shader
        #self.compute_shader.uniforms['mul'].value = 100.0
        self.ctx = ctx
        self.buf1 = buf1
        self.buf2 = buf2

    def compute(self, data):
        data = data[-1024 * 4 * 4:]
        self.compute_shader.uniforms['real_size'].value = len(data) // 4
        #self.compute_shader.uniforms['mul'].value = 100.0
        self.buf1.write(data)
        self.compute_shader.run()
        return self.buf2.read()[:len(data)]

    def destroy(self):
        self.ctx.release()
