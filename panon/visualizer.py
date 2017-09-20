import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GObject, Gdk
import cairo
import pyaudio
import numpy as np
from . import helper
from . import config


def record_pyaudio(fps, channel_count, sample_rate):
    buffer_size = sample_rate // fps * channel_count
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16,
                    channels=channel_count,
                    rate=sample_rate,
                    input=True)
    stop = False
    while not stop:
        stop = yield np.fromstring(stream.read(buffer_size), 'int16')
    stream.close()
    yield


class Visualizer(Gtk.EventBox):
    stop = False
    empty = False

    def tick(self):
        if self.stop:
            if not self.empty:
                self.sample.send(True)
                self.empty = True
                self.queue_draw()
        if not self.stop:
            if self.empty:
                self.sample = record_pyaudio(
                    self.fps, self.channel_count, self.sample_rate)
                self.empty = False
            self.queue_draw()
        return True  # Causes timeout to tick again.

    def __init__(self, background_color, foreground_color, fps=60, channel_count=2, sample_rate=44100, padding=4):
        super(Visualizer, self).__init__()
        self.sample_rate = sample_rate
        self.background_color = helper.color(background_color)
        self.history = [[]] * 8
        self.min_sample = 10
        self.max_sample = self.min_sample
        self.hue_gradient_position = 0
        if foreground_color == 'hue_gradient':
            self.update_hue_gradient()
        else:
            self.sources = [(1, helper.color(foreground_color))]
        self.padding = padding
        self.fps = fps
        self.channel_count = channel_count
        self.sample_rate = sample_rate
        self.sample = record_pyaudio(fps, channel_count, sample_rate)
        GObject.timeout_add(1000 // fps, self.tick)

        self.da = Gtk.DrawingArea()
        self.da.connect('draw', self.do_draw_cb)
        self.add(self.da)

        self.add_events(Gdk.EventMask.SCROLL_MASK)
        self.connect('scroll-event', self.do_scroll_event)
        self.connect('button-release-event', self.do_button_release_event)

    def update_hue_gradient(self):
        self.sources = [
            (4, self.create_gradient(alpha=0.1, position=self.hue_gradient_position)),
            (3, self.create_gradient(alpha=0.2, position=self.hue_gradient_position)),
            (2, self.create_gradient(alpha=0.3, position=self.hue_gradient_position)),
            (1, self.create_gradient(alpha=0.5, position=self.hue_gradient_position)),
            (0.5, self.create_gradient(alpha=1, position=self.hue_gradient_position)),
        ]

    def do_button_release_event(self, widget, event=None):
        if event and event.button == 1:
            self.stop = not self.stop
            return True
        else:
            return False

    def do_scroll_event(self, widget, e):
        if type(self.sources[0][1]) is Gdk.RGBA:
            pass
        else:
            if e.direction == Gdk.ScrollDirection.UP:
                self.hue_gradient_position += 0.02
                self.update_hue_gradient()
                return True
            elif e.direction == Gdk.ScrollDirection.DOWN:
                self.hue_gradient_position -= 0.02
                self.update_hue_gradient()
                return True

    def create_gradient(self, alpha=0.8, position=0, width=800, hue_step=60, hue_start=180):
        hue_gradient = cairo.LinearGradient(0.0, 0.0, width, 0)
        for hue in range(0, 360, hue_step):
            rgb = helper.hsv2rgb((hue + hue_start) % 360, 1, alpha)
            hue_gradient.add_color_stop_rgba(
                (hue / 360 + position) % 1, *rgb, alpha)
        hue_gradient.set_extend(cairo.EXTEND_REPEAT)
        return hue_gradient

    def do_draw_cb(self, widget, cr):
        alloc = self.get_allocation()
        w, h = alloc.width, alloc.height

        cr.set_source_rgba(*self.background_color)
        cr.rectangle(0, 0, w, h)
        cr.fill()

        if self.empty:
            return

        data = next(self.sample)
        self.history.append(data)
        self.history.pop(0)

        #fft = np.absolute(np.fft.rfft(data, n=len(data)))/len(data)
        data_history = np.concatenate(self.history)
        fft_freq = []

        def fun(start, end,  rel):
            size = len(data)
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

        x, y = self.padding, self.padding
        w, h = w - 2 * self.padding, h - 2 * self.padding

        for rel, source in self.sources:
            if type(source) is Gdk.RGBA:
                cr.set_source_rgba(*source)
            else:
                cr.set_source(source)
            cr.set_operator(cairo.OPERATOR_SOURCE)
            cr.move_to(x + 0, y + h / 2)  # middle left
            width = 2 * w / len(bins)
            for i in range(len(bins) // 2):
                height = rel * h * bins[i]
                cr.line_to(x + i * width, y + h / 2 - height / 2)
            cr.line_to(x + w, y + h / 2)  # middle right
            for i in range(len(bins) // 2, len(bins)):
                freq = len(bins) - i
                height = rel * h * bins[i]
                cr.line_to(x + freq * width, y + h / 2 + height / 2)
            cr.close_path()
            cr.fill()
