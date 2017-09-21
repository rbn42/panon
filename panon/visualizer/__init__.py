import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GObject, Gdk
import cairo
import pyaudio
import numpy as np
from .. import helper
from .. import config
from .fallback import VisualizerCairo
from .opengl import VisualizerGL
from queue import Queue
from threading import Thread


def record_pyaudio(fps, channel_count, sample_rate):
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16,
                    channels=channel_count,
                    rate=sample_rate,
                    input=True)
    stop = False
    while not stop:
        size = stream.get_read_available()
        stop = yield np.fromstring(stream.read(size), 'int16')
    stream.close()
    yield


class Visualizer(Gtk.EventBox):
    stop = False
    stop_gen_data = False

    def tick(self):
        self.queue_draw()
        return True  # Causes timeout to tick again.

    def destory(self):
        self.stop_gen_data = True

    def __init__(self, background_color, fps=60, channel_count=2, sample_rate=44100, padding=4, use_opengl=False):
        super(Visualizer, self).__init__()
        self.sample_rate = sample_rate
        self.background_color = helper.color(background_color)
        self.history = [[]] * 8
        self.data_queue = Queue(3)
        self.min_sample = 10
        self.max_sample = self.min_sample
        self.padding = padding
        self.buffer_size = sample_rate // fps * channel_count
        self.fps = fps
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.sample = record_pyaudio(fps, channel_count, sample_rate)
        GObject.timeout_add(1000 // fps, self.tick)

        self.use_opengl=use_opengl
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
                self.sample.send(True)
                self.stop = True
            else:
                self.stop = False
                self.sample = record_pyaudio(
                    self.fps, self.channel_count, self.sample_rate)
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
            return self.__getData()

    def __getData(self):
        #fft = np.absolute(np.fft.rfft(data, n=len(data)))/len(data)

        data = next(self.sample)
        self.history.append(data)
        if sum([len(d) for d in self.history[1:]]) > self.buffer_size * 8:
            self.history.pop(0)

        data_history = np.concatenate(self.history)
        fft_freq = []

        def fun(start, end,  rel):
            size = self.buffer_size
            if rel > 20:
                start, end = int(start), int(end)
                rel = int(rel)
                d = data_history[-size * rel:].reshape((rel, size))
                d = np.mean(d, axis=0)
            else:
                start = int(start * rel)
                end = int(end * rel)
                size = int(size * rel)
                d = data_history[-size:]

            fft = np.absolute(np.fft.rfft(d, n=size))
            end = min(len(fft) // 2, end)
            fft_freq.insert(0, fft[start:end])
            fft_freq.append(fft[len(fft) - end:len(fft) - start])
        # higher resolution and latency for lower frequency

        sections = 8
        r = 0.6
        rels = 8 * r**np.arange(sections)
        start = 0
        sections = []
        for rel, freq_width in zip(rels, len(data) * 1 / rels / sum(1 / rels) // 4):
            if rel > 2:
                freq_width *= rel
                pass
            sections.append((start, start + freq_width, rel))
            start += freq_width
        sections.reverse()
        for start, end, rel in sections:
            #fun(start, end, rel)
            pass

        #fun(400, len(data),  0.3)
        #fun(300, 400,  0.5)
        #fun(200,300 ,  0.75)
        #fun(150, 200,  1)
        fun(110, 150,  2)
        fun(80, 110,  3)
        fun(50, 80,  4)
        fun(30, 50,  5)
        fun(10, 30,  6)
        fun(0, 10,  8)

        fft = np.concatenate(fft_freq)

        exp = 2
        retain = (1 - config.visualizer_decay)**exp
        decay = 1 - retain

        vol = self.min_sample + np.mean(fft ** exp)
        self.max_sample = self.max_sample * retain + vol * decay
        bins = fft / self.max_sample ** (1 / exp)
        return bins
