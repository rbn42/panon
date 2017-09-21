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
        self.screen = display.screen()          # Screen obj

        self.window_gtk = Gtk.Window()
        self.setGtkProps(self.window_gtk)
        self.window_gtk.show()

        self.winid = self.window_gtk.get_window().get_xid()
        self.window_xlib = display.create_resource_object('window', self.winid)
        # Init the properties and then start the event loop
        self.setProps(self.display, self.window_xlib)
        self.setStruts(self.window_xlib)
        self.display.flush()

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
                    foreground_color=config.visualizer_foreground,
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
        win.set_wmclass("panon","Panon" )
        win.set_name("panon")
        win.set_type_hint(Gdk.WindowTypeHint.DOCK)
        win.set_decorated(False)
        win.stick()
        win.set_keep_above(True)
        win.fullscreen()

    def setProps(self, dsp, win):
        #----------------------------
        """ Set necessary X atoms and panel window properties """
        self._ABOVE = dsp.intern_atom("_NET_WM_STATE_ABOVE")
        self._BELOW = dsp.intern_atom("_NET_WM_STATE_BELOW")
        self._BLACKBOX = dsp.intern_atom("_BLACKBOX_ATTRIBUTES")
        self._CHANGE_STATE = dsp.intern_atom("WM_CHANGE_STATE")
        self._CLIENT_LIST = dsp.intern_atom("_NET_CLIENT_LIST")
        self._CURRENT_DESKTOP = dsp.intern_atom("_NET_CURRENT_DESKTOP")
        self._DESKTOP = dsp.intern_atom("_NET_WM_DESKTOP")
        self._DESKTOP_COUNT = dsp.intern_atom("_NET_NUMBER_OF_DESKTOPS")
        self._DESKTOP_NAMES = dsp.intern_atom("_NET_DESKTOP_NAMES")
        self._HIDDEN = dsp.intern_atom("_NET_WM_STATE_HIDDEN")
        self._ICON = dsp.intern_atom("_NET_WM_ICON")
        self._NAME = dsp.intern_atom("_NET_WM_NAME")
        self._RPM = dsp.intern_atom("_XROOTPMAP_ID")
        self._SHADED = dsp.intern_atom("_NET_WM_STATE_SHADED")
        self._SHOWING_DESKTOP = dsp.intern_atom("_NET_SHOWING_DESKTOP")
        self._SKIP_PAGER = dsp.intern_atom("_NET_WM_STATE_SKIP_PAGER")
        self._SKIP_TASKBAR = dsp.intern_atom("_NET_WM_STATE_SKIP_TASKBAR")
        self._STATE = dsp.intern_atom("_NET_WM_STATE")
        self._STICKY = dsp.intern_atom("_NET_WM_STATE_STICKY")
        self._STRUT = dsp.intern_atom("_NET_WM_STRUT")
        self._STRUTP = dsp.intern_atom("_NET_WM_STRUT_PARTIAL")
        self._WMSTATE = dsp.intern_atom("WM_STATE")

        P_WIDTH = self.screen.width_in_pixels

        win.set_wm_name("panon")
        win.set_wm_class("panon", "Panon")
        # win.set_wm_hints(flags=(Xutil.InputHint | Xutil.StateHint),
        #                 input=0, initial_state=1)
        win.set_wm_normal_hints(flags=(
            Xutil.PPosition | Xutil.PMaxSize | Xutil.PMinSize),
            min_width=P_WIDTH, min_height=config.height,
            max_width=P_WIDTH, max_height=config.height)
        # win.change_property(dsp.intern_atom("_WIN_STATE"),
        #                    Xatom.CARDINAL, 32, [1])
        # win.change_property(dsp.intern_atom("_MOTIF_WM_HINTS"),
        #                    dsp.intern_atom("_MOTIF_WM_HINTS"), 32, [0x2, 0x0, 0x0, 0x0, 0x0])
        #win.change_property(self._DESKTOP, Xatom.CARDINAL, 32, [0xffffffff])
        # win.change_property(dsp.intern_atom("_NET_WM_WINDOW_TYPE"),
        #                    Xatom.ATOM, 32, [dsp.intern_atom("_NET_WM_WINDOW_TYPE_DOCK")])

    #----------------------------------
    def setStruts(self, win, hidden=0):
        #----------------------------------
        """ Set the panel struts according to the state (hidden/visible) """

        P_WIDTH = self.screen.width_in_pixels
        if config.position == 'bottom':
            P_LOCATION = self.screen.height_in_pixels - config.height
        elif config.position == 'top':
            P_LOCATION = 0
        P_START = 0

        win.configure(y=P_LOCATION, height=config.height)

        if P_LOCATION == 0:
            # top
            if not hidden:
                top = config.height
            else:
                top = HIDDEN_SIZE

            top_start = P_START
            top_end = P_START + P_WIDTH
            bottom = bottom_start = bottom_end = 0
        else:
            # bottom
            top = top_start = top_end = 0
            if not hidden:
                bottom = config.height
            else:
                bottom = HIDDEN_SIZE

            bottom_start = P_START
            bottom_end = P_START + P_WIDTH

        win.change_property(self._STRUT, Xatom.CARDINAL,
                            32, [0, 0, top, bottom])
        win.change_property(self._STRUTP, Xatom.CARDINAL, 32, [0, 0, top, bottom,
                                                               0, 0, 0, 0, top_start, top_end, bottom_start, bottom_end])


from .singleton import Singleton
from threading import Thread
import os
from Xlib import X, display, error, Xatom, Xutil
import Xlib.protocol.event
def main():
    SOCKET_FILE = "/run/user/%s/gtk_visualizer.socket" % os.getuid()
    sin = Singleton(SOCKET_FILE)
    if sin.start():
        # Thread(target=sin.loop).start()
        p = Panel(display.Display())
        import signal
        signal.signal(signal.SIGINT, signal.SIG_DFL)
        Gtk.main()

if __name__=='__main__':
    main()
