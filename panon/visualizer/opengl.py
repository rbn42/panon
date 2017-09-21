from OpenGL.GLU import *
from OpenGL.GL import *
from OpenGL import GL
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GObject
from OpenGL.GL import shaders
from OpenGL.raw.GL.ARB.vertex_array_object import glGenVertexArrays, \
    glBindVertexArray
import numpy as np
from PIL import Image
from .. import glsl


class VisualizerGL(Gtk.GLArea):
    empty = False

    def __init__(self, getData):
        super(VisualizerGL, self).__init__()
        self.getData = getData
        self.set_required_version(3, 3)
        # TODO This line brings terrible performance.
        self.set_has_alpha(True)
        self.connect('realize', self.on_configure_event)
        self.connect('render', self.on_draw)
        self.set_double_buffered(False)

    def stop(self):
        self.empty = True

    def start(self):
        self.empty = False

    def loadTex(self, data):
        img_data = np.zeros((3, data.shape[0], 4), dtype='uint8')
        img_data[:, :, 0] = data * 256
        image =  Image.fromarray(img_data)
        width = image.size[0]
        height = image.size[1]
        image_bytes = image.convert("RGBA").tobytes("raw", "RGBA", 0, -1)
        gluBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, width, height,
                          GL_RGBA, GL_UNSIGNED_BYTE, image_bytes)

    def on_configure_event(self, widget):
        widget.make_current()
        context = widget.get_context()
        vs = shaders.compileShader(
            glsl.load('./vert.glsl'), GL.GL_VERTEX_SHADER)
        fs = shaders.compileShader(
            glsl.load('./frag.glsl'), GL.GL_FRAGMENT_SHADER)
        self.program = shaders.compileProgram(vs, fs)

        self.vertex_array_object = GL.glGenVertexArrays(1)
        GL.glBindVertexArray(self.vertex_array_object)
        vertex_buffer = GL.glGenBuffers(1)
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vertex_buffer)

        position = GL.glGetAttribLocation(self.program, 'a_position')

        GL.glEnableVertexAttribArray(position)
        GL.glVertexAttribPointer(
            position, 4, GL.GL_FLOAT, False, 0, ctypes.c_void_p(0))

        vertices = [
            1,  1, 0, 1,
            -1,  1, 0, 1,
            -1, -1, 0, 1,
            1,  1, 0, 1,
            1,  -1, 0, 1,
            -1, -1, 0, 1,
        ]

        vertices = np.array(vertices, dtype=np.float32)

        GL.glBufferData(GL.GL_ARRAY_BUFFER, 96,
                        vertices, GL.GL_STATIC_DRAW)
        GL.glBindVertexArray(0)
        GL.glDisableVertexAttribArray(position)
        GL.glBindBuffer(GL.GL_ARRAY_BUFFER, 0)
        self.tex1 = glGenTextures(1)
        return True

    def on_draw(self, widget, *args):
        if self.empty:
            return
        data = self.getData()
        GL.glBindTexture(GL_TEXTURE_2D, self.tex1)
        self.loadTex(data)
        widget.attach_buffers()
        GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT)
        GL.glUseProgram(self.program)
        GL.glBindVertexArray(self.vertex_array_object)
        GL.glBindTexture(GL_TEXTURE_2D, self.tex1)
        GL.glDrawArrays(GL.GL_TRIANGLES, 0, 6)
        GL.glBindVertexArray(0)
        GL.glUseProgram(0)
        GL.glFlush()
        return True
