import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GObject
from ewmh import EWMH
from logging import getLogger
from Xlib import X, Xutil, Xatom
import Xlib
import cairo
import os
ewmh = EWMH()

childLogger = getLogger(__name__)


class Taskbar(Gtk.EventBox):

    def __init__(self, display, size,
                 background_color,
                 fps=60, animation_duration=0.1):
        super(Taskbar, self).__init__()
        self.display = display
        self.screen = display.screen()          # Screen obj
        self.root = self.screen.root          # Display root

        self.setup_atom()
        self.size = size
        self.fps = fps
        self.background_color = background_color
        self.animation_duration = animation_duration
        self.tasks_draw = []

        self.icontheme = Gtk.IconTheme()
        self.icontheme.set_screen(self.get_screen())

        lst = self.root.get_full_property(
            self._CLIENT_LIST, Xatom.WINDOW).value
        for _id in lst:
            self.addTask(_id)

        self.da = Gtk.DrawingArea()
        self.da.connect('draw', self.do_draw_cb)
        self.add(self.da)

        self.create_menu()

        self.add_events(Gdk.EventMask.SCROLL_MASK)
        self.connect('button-release-event', self.do_button_release_event)
        self.connect('scroll-event', self.do_scroll_event)

        root = self.display.screen().root
        root.change_attributes(event_mask=X.SubstructureNotifyMask)
        GObject.timeout_add(200, self.tick)
        GObject.timeout_add(1000 // self.fps, self.update)

    def do_button_release_event(self, widget, event):
        if event.button == 1:
            self.toggleWindow(self.getTask(event))
            return True
        elif event.button == 3:
            self.target_task = self.getTask(event)
            self.menu.popup(None, None, None, None, 0,
                            Gtk.get_current_event_time())
            return True

    def do_scroll_event(self, widget, e):
        if e.direction == Gdk.ScrollDirection.UP:
            self.activateWindow(self.getTask(e), offset=1)
            return True
        elif e.direction == Gdk.ScrollDirection.DOWN:
            self.activateWindow(self.getTask(e), offset=-1)
            return True

    def close_all(self, event):
        for win in self.target_task.windows:
            os.system('wmctrl -i -c %s' % win.id)
            # win.destroy()
        return True

    def hide_task(self, event):
        self.target_task.hide()
        self.update(force_draw=True)
        return True

    def setup_atom(self):
        self._NET_WM_STATE_SKIP_TASKBAR = self.display.intern_atom(
            '_NET_WM_STATE_SKIP_TASKBAR')
        self._NET_WM_WINDOW_TYPE_DOCK = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_DOCK')
        self._NET_WM_WINDOW_TYPE_NORMAL = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_NORMAL')
        self._NET_WM_WINDOW_TYPE_MENU = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_MENU')
        self._NET_WM_WINDOW_TYPE_SPLASH = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_SPLASH')
        self._NET_WM_WINDOW_TYPE_TOOLBAR = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_TOOLBAR')
        self._NET_WM_WINDOW_TYPE_UTILITY = self.display.intern_atom(
            '_NET_WM_WINDOW_TYPE_UTILITY')
        self._NET_WM_STATE_HIDDEN = self.display.intern_atom(
            "_NET_WM_STATE_HIDDEN")
        self.WM_CHANGE_STATE = self.display.intern_atom("WM_CHANGE_STATE")

        dsp = self.display
        self._CLIENT_LIST = dsp.intern_atom("_NET_CLIENT_LIST")

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

    #------------------------------------------------
    def sendEvent(self, win, ctype, data, mask=None):
        #------------------------------------------------
        """ Send a ClientMessage event to the root """
        data = (data + [0] * (5 - len(data)))[:5]
        ev = Xlib.protocol.event.ClientMessage(
            window=win, client_type=ctype, data=(32, (data)))

        if not mask:
            mask = (X.SubstructureRedirectMask | X.SubstructureNotifyMask)
        self.root.send_event(ev, event_mask=mask)

    def create_menu(self):
        self.menu = Gtk.Menu()
        i1 = Gtk.MenuItem("Close All")
        i1.connect("activate", self.close_all)
        self.menu.append(i1)
        i2 = Gtk.MenuItem("Hide")
        i2.connect("activate", self.hide_task)
        self.menu.append(i2)
        self.menu.show_all()

    def activateWindow(self, taskcat, offset=1):
        win = taskcat.windows[0]
        if win.id == ewmh.getActiveWindow().id:
            taskcat.windows = taskcat.windows[offset:] +\
                taskcat.windows[:offset]
            win = taskcat.windows[0]
        os.system('wmctrl -i -a %d' % win.id)
        # win.map()
        # ewmh.setActiveWindow(win)
        # ewmh.display.flush()

    def toggleWindow(self, taskcat):
        winids = [win.id for win in taskcat.windows]
        if ewmh.getActiveWindow().id in winids:
            for win in taskcat.windows:
                self.sendEvent(win, self.WM_CHANGE_STATE,
                               [Xutil.IconicState])
        else:
            for win in taskcat.windows:
                if self._NET_WM_STATE_HIDDEN not in ewmh.getWmState(win):
                    ewmh.setActiveWindow(win)
                    break
            else:
                for win in taskcat.windows:
                    win.map()
        ewmh.display.flush()
        self.display.flush()

    def getTask(self, event):
        index = event.x // self.size
        index = int(index)
        return self.tasks_draw[index]  # .windows[0]

    def tick(self):
        childLogger.debug('tick')
        draw = False
        self.display.sync()
        num = self.display.pending_events()
        childLogger.debug('events:%s', num)
        for _ in range(num):
            e = self.display.next_event()
            if e.type == X.MapNotify and e.window:
                if self.addTask(e.window.id):
                    draw = True
            elif e.type == X.DestroyNotify:
                if self.removeTask(e.window):
                    draw = True
        if draw:
            GObject.timeout_add(1000 // self.fps, self.update)
        return True  # Causes timeout to tick again.

    def do_draw_cb(self, widget, cr):
        w = self.size * sum([t.size for t in self.tasks_draw])
        h = self.size

        cr.set_source_rgba(*self.background_color)
        cr.rectangle(0, 0, w, h)
        cr.fill()
        # x, y = self.size / 2, self.size / 2
        x, y_center, w, h = 0, h / 2, h, h
        for task in self.tasks_draw:
            rel = task.size
            if rel <= 0:
                continue
            rel_x, rel_y = x / rel, y_center / rel
            if rel < 1:
                cr.scale(rel, rel)
            cr.set_source_surface(task.icon, rel_x, rel_y - h / 2)
            cr.get_source().set_filter(cairo.FILTER_FAST)
            if rel < 1:
                cr.identity_matrix()
            cr.paint()
            x += w * rel

    def update(self, force_draw=False):
        draw = False
        for t in self.tasks_draw:
            if t.animate(1 / self.animation_duration / self.fps):
                draw = True
            elif t.destroy():
                self.tasks_draw.remove(t)
                t.icon.finish()
        if draw or force_draw:
            w = self.size * sum([t.size for t in self.tasks_draw])
            h = self.size
            self.set_size_request(w, h)
            self.queue_draw()
            return True

    def removeTask(self, win):
        for t in self.tasks_draw:
            for w in t.windows:
                if win.id == w.id:
                    t.windows.remove(w)
                    return True

    def addTask(self, winid):
        """
        用wmclass寻找icon的话,mangameeya的icon无法读取,xdg文件中的qmlterm的icon页无法读取.docky都做得到.前者compiz做得到,后者做不到
        """
        win = self.display.create_resource_object("window", winid)
        try:
            lst = win.get_full_property(self._STATE, Xatom.ATOM).value
            if self._SKIP_TASKBAR in lst:
                return False
        except:
            return False

        try:
            for _ in range(10):
                wm_class = win.get_full_property(Xatom.WM_CLASS, Xatom.STRING)
                if wm_class:
                    wm_class = wm_class.value.decode().split("\0")[:2]
                    break
            else:
                return False
                wm_class = ["", ""]
        except:
            return False

        if self._NET_WM_WINDOW_TYPE_DOCK in ewmh.getWmWindowType(win):
            return False

        for taskcat in self.tasks_draw:
            if taskcat.wm_class == wm_class:
                for w in taskcat.windows:
                    if w.id == win.id:
                        return False
                taskcat.windows.append(win)
                return False
        else:
            for icon_name in wm_class:
                icon_name = icon_name.lower()
                if self.icontheme.has_icon(icon_name):
                    icon = self.icontheme.load_surface(icon_name, self.size,
                                                       1, self.get_window(), 0)
                    taskcat = TaskCat(self.display,  icon, wm_class)
                    taskcat.windows.append(win)
                    self.tasks_draw.append(taskcat)
                    mask = X.PropertyChangeMask | X.FocusChangeMask | X.StructureNotifyMask
                    # win.change_attributes(event_mask=mask)
                    return True
        return False


class TaskCat:

    def __init__(self, display,  icon, wm_class):
        self.windows = []
        self.icon = icon
        self.wm_class = wm_class
        self.size = 0
        self.hidden=False

    def destroy(self):
        return len(self.windows) < 1 and self.size <= 0

    def hide(self):
        self.size=0.01
        self.hidden=True

    def animate(self, animate_step):
        if len(self.windows) < 1:
            if self.size > 0:
                self.size -= animate_step
                self.size = max(0, self.size)
                return True
        else:
            if self.size < 1 and not self.hidden:
                self.size += animate_step
                self.size = min(1, self.size)
                return True
