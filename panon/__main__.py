import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import sys
from .visualizer import Visualizer
from .shortcut import Shortcut
from .taskbar import Taskbar
import logging
from .multiload import Multiload
from . import config
from . import helper

if config.log == 'debug':
    logging.basicConfig(level=logging.DEBUG)

style_provider = Gtk.CssProvider()
style_provider.load_from_data(config.style_sheet.encode())

Gtk.StyleContext.add_provider_for_screen(
    Gdk.Screen.get_default(),
    style_provider,
    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)


class Panel:

    def destroy(self, window):
        Gtk.main_quit()

    def __init__(self, display):
        self.background_color = helper.color(config.background_color)

        self.display = display                   # Display obj

        self.window_gtk = Gtk.Window()
        self.setGtkProps(self.window_gtk)
        self.window_gtk.show()

        self.winid = self.window_gtk.get_window().get_xid()
        from . import xpanel
        xpanel.Panel(display, self.winid, config.position, config.height)

        self.box = Gtk.Box(Gtk.Orientation.HORIZONTAL, 0)
        #self.box.override_background_color(Gtk.StateType.NORMAL, self.background_color)
        if config.fake_shadow:
            ctx = self.box.get_style_context()
            if config.position == 'bottom':
                ctx.add_class('fake-shadow-top')
            elif config.position == 'top':
                ctx.add_class('fake-shadow-bottom')

        self.window_gtk.add(self.box)
        for section in config.sections:
            if section == 'visualizer':
                self.visualizer = Visualizer(
                    background_color=config.visualizer_background,
                    padding=config.visualizer_padding)
                self.box.pack_start(self.visualizer, True, True, 0)
            elif section == 'taskbar':
                self.taskbar = Taskbar(self.display,
                                       background_color=self.background_color,
                                       size=config.height,)
                self.box.pack_start(self.taskbar, False, False, 0)
            elif type(section) is not str:
                self.box.pack_start(Shortcut(
                    background_color=self.background_color,
                    size=config.height, shortcut=section), False, False, 0)
            elif section == 'multiload':
                colors = {'cpu': {'background': config.multiload_cpu_background,
                                  'foreground': config.multiload_cpu_foreground, },
                          'mem': {'background': config.multiload_mem_background,
                                  'foreground': config.multiload_mem_foreground, },
                          'net': {'background': config.multiload_net_background,
                                  'foreground': config.multiload_net_foreground, },
                          'disk': {'background': config.multiload_disk_background,
                                   'foreground': config.multiload_disk_foreground, }, }
                w = config.height * 2 * \
                    config.multiload_layout[0] // config.multiload_layout[1]

                self.multiload_cpu = Multiload(
                    self.background_color,
                    colors, w, config.height,
                    fake_shadow=config.multiload_fake_shadow,
                    interval=config.multiload_interval,
                    layout=config.multiload_layout,
                    inner_gap=config.multiload_inner_gap,
                    outer_gap=config.multiload_outer_gap,
                )
                self.box.pack_start(self.multiload_cpu, False, False, 0)
        # menu
        self.create_menu()
        # show all
        self.window_gtk.connect_after('destroy', self.destroy)
        self.window_gtk.show_all()

    def addTime(self, expand, fill, padding):
        label = Gtk.Label()
        label.set_text("time")
        self.box.pack_start(label, expand, fill, padding)

    def quit(self, e):
        self.multiload_cpu.destory()
        self.visualizer.destory()
        Gtk.main_quit()

    def create_menu(self):
        self.menu = Gtk.Menu()
        i1 = Gtk.MenuItem("Quit")
        i1.connect("activate", self.quit)
        self.menu.append(i1)
        self.window_gtk.connect('button-release-event',
                                lambda b, e: e.button == 3
                                and self.menu.popup(
                                    None, None, None, None, 0,
                                    Gtk.get_current_event_time()))
        self.menu.show_all()

    def setGtkProps(self, win):
        win.set_app_paintable(True)
        screen = win.get_screen()
        rgba = screen.get_rgba_visual()
        win.set_visual(rgba)
        win.set_wmclass("panon", "Panon")
        win.set_name("panon")
        win.set_type_hint(Gdk.WindowTypeHint.DOCK)
        win.set_decorated(False)
        win.stick()
        win.set_keep_above(True)
        win.fullscreen()


from .singleton import Singleton
from threading import Thread
import os
from Xlib import display


def main():
    SOCKET_FILE = "/run/user/%s/gtk_visualizer.socket" % os.getuid()
    sin = Singleton(SOCKET_FILE)
    if sin.start():
        # Thread(target=sin.loop).start()
        p = Panel(display.Display())
        import signal
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        Gtk.main()


if __name__ == '__main__':
    main()
