import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GObject, Pango
import os
import subprocess


class Shortcut(Gtk.EventBox):
    def __init__(self, background_color, size, shortcut):
        super(Shortcut, self).__init__()

        self.override_background_color(Gtk.StateType.NORMAL, background_color)
        self.shortcut = shortcut

        if 'icon-name' in shortcut:
            icon = Gtk.Image.new_from_icon_name(shortcut['icon-name'], size)
            self.add(icon)
        if 'auto-command' in shortcut:
            self.label = Gtk.Label()
            self.label.set_single_line_mode(True)
            self.label.set_ellipsize(Pango.EllipsizeMode.END)
            if 'max-width' in shortcut:
                w = shortcut['max-width']
                self.label.set_max_width_chars(w)
            ctx = self.label.get_style_context()
            ctx.add_class(shortcut.get('style-class','label'))
            self.add(self.label)
            self.tick()
            GObject.timeout_add(1000 * shortcut['interval'], self.tick)

        self.add_events(Gdk.EventMask.SCROLL_MASK)
        self.connect('scroll-event', self.do_scroll_event)
        self.connect('button-release-event', self.do_button_release_event)

    def tick(self):
        text = subprocess.check_output(self.shortcut['auto-command'], shell=True)
        text = text.decode(errors='ignore')
        text = text.strip()
        self.label.set_text(text)
        return True

    def do_scroll_event(self, widget, e):
        if e.direction == Gdk.ScrollDirection.UP:
            if 'scroll-up' in self.shortcut:
                os.system(self.shortcut['scroll-up'])
            return True
        elif e.direction == Gdk.ScrollDirection.DOWN:
            if 'scroll-down' in self.shortcut:
                os.system(self.shortcut['scroll-down'])
            return True

    def do_button_release_event(self, widget, event):
        if event.button == 1:
            if 'click' in self.shortcut:
                os.system(self.shortcut['click'])
                if self.shortcut.get('refresh-on-click',False):
                    self.tick()
            return True
        if event.button == 3:
            if 'rightclick' in self.shortcut:
                os.system(self.shortcut['rightclick'])
            return True
