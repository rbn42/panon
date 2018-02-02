import gi
gi.require_version('Gtk', '3.0')
import pyaudio
from logging import getLogger
from gi.repository import Gtk, Gdk
import cairo
from threading import Thread
import psutil
from . import helper

childLogger = getLogger(__name__)

vertical = True


class Multiload(Gtk.DrawingArea):
    stop = False

    def __init__(
            self,
            background_color,
            colors,
            width,
            height,
            fake_shadow=True,
            grid=(4, 3),
            inner_gap=2,
            outer_gap=2,
            layout=(2, 2),
            interval=1,
    ):
        super(Multiload, self).__init__()

        self.interval = interval
        self.colors = colors
        self.show_swap_mem = False
        self.background_color = background_color
        self.height = height
        self.width = width
        self.fake_shadow = fake_shadow
        self.grid = grid
        self.inner_gap = inner_gap
        self.outer_gap = outer_gap
        self.unit_width = (width - 2 * outer_gap) // layout[0] - inner_gap * 2
        self.unit_height = (height - 2 * outer_gap) // layout[1] - inner_gap * 2
        self.layout = layout

        self.override_background_color(Gtk.StateType.NORMAL, Gdk.RGBA(alpha=0))

        self.set_size_request(self.width, self.height)
        self.history = [None] * self.unit_width
        self.connect('draw', self.do_draw_cb)
        Thread(target=self.tick).start()

    def fetch_net(self):
        prev_net_io = psutil.net_io_counters(pernic=True)
        while True:
            net_io = psutil.net_io_counters(pernic=True)
            sent, recv = 0, 0
            for interface in net_io:
                if interface == 'lo':
                    continue
                sent += net_io[interface].bytes_sent - \
                    prev_net_io[interface].bytes_sent
                recv += net_io[interface].bytes_recv - \
                    prev_net_io[interface].bytes_recv
            yield sent, recv
            prev_net_io = net_io

    def fetch_mem(self):
        while True:
            vm = psutil.virtual_memory()
            total = vm.total
            if self.show_swap_mem:
                sm = psutil.swap_memory()
                total = sm.total
            result = [vm.used / total]
            if self.show_swap_mem:
                result.append(sm.used / total)
            yield result

    def fetch_disk(self):
        prev_disk_io = psutil.disk_io_counters(perdisk=False)
        while True:
            disk_io = psutil.disk_io_counters(perdisk=False)
            yield disk_io.write_bytes - prev_disk_io.write_bytes, disk_io.read_bytes - prev_disk_io.read_bytes
            prev_disk_io = disk_io

    def tick(self):
        net_data = self.fetch_net()
        mem_data = self.fetch_mem()
        disk_data = self.fetch_disk()
        while not self.stop:
            childLogger.debug('tick')
            self.history.pop(0)
            cpu = psutil.cpu_percent(self.interval, percpu=True)
            cpu = [c / 100 / len(cpu) for c in cpu]
            data = {
                "cpu": cpu,
                'net': next(net_data),
                'disk': next(disk_data),
                'mem': next(mem_data),
            }
            childLogger.debug('Multiload data:%s', data)
            self.history.append(data)
            self.queue_draw()

    def destory(self):
        childLogger.debug('stop')
        self.stop = True

    def do_draw_cb(self, widget, cr):
        cr.set_source_rgba(*self.background_color)
        cr.rectangle(0, 0, self.width, self.height)
        cr.fill()

        childLogger.debug('cairo start')
        if not self.history[-1]:
            return

        max_net = 1 + max([sum(item['net']) for item in self.history if item])
        max_disk = 1 + max([sum(item['disk']) for item in self.history if item])
        postions = []
        for x in range(self.layout[0]):
            for y in range(self.layout[1]):
                _x = self.outer_gap + x * \
                    (self.unit_width + 2 * self.inner_gap)
                _y = self.outer_gap + y * \
                    (self.unit_height + 2 * self.inner_gap)
                postions.append((_x, _y))

        for unit, max_value, position in zip(['cpu', 'mem', 'net', 'disk'], [1, 1, max_net, max_disk], postions):
            x, y = position
            self.draw_unit(cr, x + self.inner_gap, y + self.inner_gap, unit, max_value)
        childLogger.debug('cairo end')

    def draw_unit(self, cr, x, y, unit, max_value=1):
        colors = self.colors[unit]['foreground']
        back = self.colors[unit]['background']

        cr.set_operator(cairo.OPERATOR_SOURCE)
        cr.set_source_rgba(*helper.color(back))
        cr.rectangle(x, y, self.unit_width, self.unit_height)
        cr.fill()

        if self.grid:
            cr.set_line_width(1)
            cr.set_source_rgba(1, 1, 1, 0.3)
            for i in range(1, self.grid[0]):
                _x = -.5 + int(x + self.unit_width / self.grid[0] * i)
                cr.move_to(_x, -.5 + y)
                cr.line_to(_x, -.5 + y + self.unit_height)
            for i in range(1, self.grid[1]):
                _y = -.5 + int(y + self.unit_height / self.grid[1] * i)
                cr.move_to(-.5 + x, _y)
                cr.line_to(-.5 + x + self.unit_width, _y)
            cr.stroke()

        cr.set_operator(cairo.OPERATOR_OVER)
        line_count = len(self.history[-1][unit])
        for num_line in range(line_count):
            cr.set_source_rgba(*helper.color(colors[num_line % len(self.colors)]))
            cr.move_to(x, y + self.unit_height)
            self.draw_line(x, y, cr, lambda item: sum(item[unit][num_line:]) / max_value)
            self.draw_line(x, y, cr, 'bottom', True)
            cr.close_path()
            cr.fill()
        if self.fake_shadow:
            cr.set_line_width(1)
            cr.set_source_rgba(1, 1, 1, 1)
            cr.move_to(-.5 + x + self.unit_width, -.5 + y)
            cr.line_to(-.5 + x + self.unit_width, -.5 + y + self.unit_height)
            cr.line_to(-.5 + x, -.5 + y + self.unit_height)
            cr.stroke()
            cr.set_source_rgba(0, 0, 0, 1)
            cr.move_to(-.5 + x + self.unit_width, -.5 + y)
            cr.line_to(-.5 + x, -.5 + y)
            cr.line_to(-.5 + x, -.5 + y + self.unit_height)
            cr.stroke()
        return line_count

    def draw_line(self, x, y, cr, calc, reverse=False):
        if calc in ('top', 'bottom'):
            h = 0 if calc == 'top' else self.unit_height
            start = self.unit_width if reverse else 0
            end = 0 if reverse else self.unit_height
            cr.line_to(x + start, y + h)
            cr.line_to(x + end, y + h)
        else:
            data = self.history[::-1 if reverse else 1]
            for w, item in enumerate(data):
                h = calc(item) if item else 0
                h = self.unit_height * (1 - h)
                cr.line_to(x + w, y + h)
