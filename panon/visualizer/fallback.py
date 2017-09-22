import cairo
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
from .. import helper


class VisualizerCairo(Gtk.DrawingArea):
    empty = False

    def __init__(self, background_color, getData, padding):
        super(VisualizerCairo, self).__init__()
        self.hue_gradient_position = 0
        self.padding = padding
        self.background_color = background_color
        self.getData = getData
        self.update_hue_gradient()
        self.add_events(Gdk.EventMask.SCROLL_MASK)
        self.connect('scroll-event', self.do_scroll_event)
        self.connect('draw', self.do_draw_cb)

    def stop(self):
        self.empty = True

    def start(self):
        self.empty = False

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

    def update_hue_gradient(self):
        self.sources = [
            (4, self.create_gradient(alpha=0.1, position=self.hue_gradient_position)),
            (3, self.create_gradient(alpha=0.2, position=self.hue_gradient_position)),
            (2, self.create_gradient(alpha=0.3, position=self.hue_gradient_position)),
            (1, self.create_gradient(alpha=0.5, position=self.hue_gradient_position)),
            (0.5, self.create_gradient(alpha=1, position=self.hue_gradient_position)),
        ]

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
        bins = self.getData()
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
