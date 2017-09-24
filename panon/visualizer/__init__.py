import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GObject
import cairo
from .. import helper
from .. import config
from .fallback import VisualizerCairo
from .opengl import VisualizerGL
from .spectrum import Spectrum
from queue import Queue
from threading import Thread


class Visualizer(Gtk.EventBox):
    stop = False
    stop_gen_data = False

    def tick(self):
        self.queue_draw()
        return True  # Causes timeout to tick again.

    def destory(self):
        self.stop_gen_data = True

    def __init__(self, background_color, fps=60, padding=4, use_opengl=False):
        super(Visualizer, self).__init__()
        self.background_color = helper.color(background_color)
        self.data_queue = Queue(3)

        self.padding = padding
        self.spectrum = Spectrum(fps,  config.visualizer_decay)
        GObject.timeout_add(1000 // fps, self.tick)

        self.use_opengl = use_opengl

        if use_opengl:
            Thread(target=self.run).start()
            self.da = VisualizerGL(self.getData)
            ol = Gtk.Overlay()
            ol.add(self.da)
            label = Gtk.Label()
            label.set_text("111111")
            label.show()
            # ol.add(label)
            label = Gtk.Label()
            label.set_text("bbbbbbbbbHHHHHH")
            label.show()
            ol.add(label)
            self.override_background_color(
                Gtk.StateType.NORMAL, self.background_color)
            self.da = ol
        else:
            self.da = VisualizerCairo(
                self.background_color, self.getData, self.padding)
        self.add(self.da)
        self.connect('button-release-event', self.do_button_release_event)

    def do_button_release_event(self, widget, event=None):
        if event and event.button == 1:
            if not self.stop:
                self.da.stop()
                self.spectrum.stop()
                self.stop = True
            else:
                self.stop = False
                self.spectrum.start()
                self.da.start()
            return True
        else:
            return False

    def run(self):
        while not self.stop_gen_data:
            self.data_queue.put(self.__getData())

    def getData(self):
        if self.use_opengl:
            return self.data_queue.get()
        else:
            return self.spectrum.getData()
