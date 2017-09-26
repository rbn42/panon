import struct

import ModernGL
from PySide import QtOpenGL
from PySide.QtCore import *
from PySide.QtGui import *

from .spectrum import Spectrum
from .. import config
from .. import glsl
import numpy as np
from PIL import Image


class QGLControllerWidget(QtOpenGL.QGLWidget):
    def __init__(self, fps=60, padding=4, use_opengl=False):

        fmt = QtOpenGL.QGLFormat()
        fmt.setVersion(3, 3)
        fmt.setProfile(QtOpenGL.QGLFormat.CoreProfile)
        fmt.setSampleBuffers(True)
        super(QGLControllerWidget, self).__init__(fmt, None)

        self.spectrum = Spectrum(fps,  config.visualizer_decay)

    def initializeGL(self):
        self.ctx = ModernGL.create_context()
        prog = self.ctx.program([
            self.ctx.vertex_shader(glsl.load('vert2.glsl')),
            self.ctx.fragment_shader(glsl.load('frag2.glsl')),
        ])

        vbo = self.ctx.buffer(struct.pack(
            '12f', 1, 1, -1, -1, 1, -1, 1, 1, -1, 1, -1, -1))
        self.vao = self.ctx.simple_vertex_array(prog, vbo, ['vert'])

        data = self.spectrum.getData()
        data = np.concatenate([data[0], data[1, ::-1]])
        img = self.loadTex(data)
        self.tex1 = self.ctx.texture(img.size, 4, img.tobytes())
        self.tex1.use()

    def paintGL(self):
        data = self.spectrum.getData()
        data = np.concatenate([data[0], data[1, ::-1]])
        img = self.loadTex(data)
        image_bytes = img.convert("RGBA").tobytes("raw", "RGBA", 0, -1)
        self.tex1.write(image_bytes)

        self.ctx.viewport = (0, 0, self.width(), self.height())
        self.ctx.clear(0.9, 0.9, 0.9)
        self.vao.render()
        # self.ctx.finish()

    def loadTex(self, data):
        img_data = np.zeros((3, data.shape[0], 4), dtype='uint8')
        img_data[:, :, 0] = data * 256
        image = Image.fromarray(img_data)
        return image


if __name__ == '__main__':
    app = QApplication([])
    window = QGLControllerWidget()
    window.show()

    w = window
    timer = QTimer(w)
    w.connect(timer, SIGNAL("timeout()"), w.updateGL)
    timer.start(1000 // 60)
    app.exec_()
