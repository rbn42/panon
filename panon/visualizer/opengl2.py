import struct

import ModernGL
from PySide import QtOpenGL
from PySide.QtCore import *
from PySide.QtGui import *

from .spectrum import Spectrum
from .. import glsl
import numpy as np
from PIL import Image


class QGLControllerWidget(QtOpenGL.QGLWidget):
    def __init__(self, fps=60, decay=0.01):

        fmt = QtOpenGL.QGLFormat()
        fmt.setVersion(3, 3)
        fmt.setProfile(QtOpenGL.QGLFormat.CoreProfile)
        fmt.setSampleBuffers(True)
        super(QGLControllerWidget, self).__init__(fmt, None)

        self.spectrum = Spectrum(fps,  decay)

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
        img = self.loadTex(data)
        self.tex1 = self.ctx.texture(img.size, 4, img.tobytes())
        self.tex1.use()

#        self.ctx.enable(ModernGL.BLEND)

    def paintGL(self):
        data = self.spectrum.getData()
        img = self.loadTex(data)
        image_bytes = img.convert("RGBA").tobytes("raw", "RGBA", 0, -1)
        self.tex1.write(image_bytes)

        self.ctx.viewport = (0, 0, self.width(), self.height())
        #self.ctx.clear(0.9, 0.9, 0.9)
        self.vao.render()
        # self.ctx.finish()

    def loadTex(self, data):
        data = data / 3.0
        data = np.clip(data, 0, 0.99)

        img_data = np.zeros((3, data.shape[1], 4), dtype='uint8')
        img_data[:, :, 0] = data[0] * 256
        img_data[:, :, 1] = data[1] * 256
        image = Image.fromarray(img_data)
        return image


if __name__ == '__main__':
    app = QApplication([])
    qgl = QGLControllerWidget()

    window = qgl
    window.setAttribute(Qt.WA_TranslucentBackground)
    window.show()

    timer = QTimer(qgl)
    qgl.connect(timer, SIGNAL("timeout()"), qgl.updateGL)
    timer.start(1000 // 60)

    winid = window.winId()
    from .. import xpanel
    from Xlib import display
    xpanel.Panel(display.Display(), winid, 'bottom', 32)
    import signal
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    app.exec_()
