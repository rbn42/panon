from Xlib import X, error, Xatom, Xutil
import Xlib.protocol.event


class Panel:
    def __init__(self, display, winid, position, height):
        self.winid = winid
        self.position = position
        self.height = height
        self.display = display                   # Display obj
        self.screen = display.screen()          # Screen obj
        self.root = self.screen.root          # Display root
        self.window_xlib = display.create_resource_object('window', self.winid)

        self.setProps(self.display, self.window_xlib)
        self.setStruts(self.window_xlib)
        self.stick()
        self.skip_pager()
        self.skip_taskbar()
        self.above()
        self.display.flush()

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

    def skip_pager(self):
        win = self.window_xlib
        self.sendEvent(win, self._STATE, [1, self._SKIP_PAGER])

    def skip_taskbar(self):
        win = self.window_xlib
        self.sendEvent(win, self._STATE, [1, self._SKIP_TASKBAR])

    def above(self):
        win = self.window_xlib
        self.sendEvent(win, self._STATE, [1, self._ABOVE])

    def stick(self):
        win = self.window_xlib
        self.sendEvent(win, self._STATE, [1, self._STICKY])

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
            min_width=P_WIDTH, min_height=self.height,
            max_width=P_WIDTH, max_height=self.height)
        # win.change_property(dsp.intern_atom("_WIN_STATE"),
        #                    Xatom.CARDINAL, 32, [1])
        # win.change_property(dsp.intern_atom("_MOTIF_WM_HINTS"),
        #                    dsp.intern_atom("_MOTIF_WM_HINTS"), 32, [0x2, 0x0, 0x0, 0x0, 0x0])
        #win.change_property(self._DESKTOP, Xatom.CARDINAL, 32, [0xffffffff])
        win.change_property(dsp.intern_atom("_NET_WM_WINDOW_TYPE"),
                            Xatom.ATOM, 32, [dsp.intern_atom("_NET_WM_WINDOW_TYPE_DOCK")])

    #----------------------------------
    def setStruts(self, win, hidden=0):
        #----------------------------------
        """ Set the panel struts according to the state (hidden/visible) """

        P_WIDTH = self.screen.width_in_pixels
        if self.position == 'bottom':
            P_LOCATION = self.screen.height_in_pixels - self.height
        elif self.position == 'top':
            P_LOCATION = 0
        P_START = 0

        win.configure(y=P_LOCATION, height=self.height)

        if P_LOCATION == 0:
            # top
            if not hidden:
                top = self.height
            else:
                top = HIDDEN_SIZE

            top_start = P_START
            top_end = P_START + P_WIDTH
            bottom = bottom_start = bottom_end = 0
        else:
            # bottom
            top = top_start = top_end = 0
            if not hidden:
                bottom = self.height
            else:
                bottom = HIDDEN_SIZE

            bottom_start = P_START
            bottom_end = P_START + P_WIDTH

        win.change_property(self._STRUT, Xatom.CARDINAL,
                            32, [0, 0, top, bottom])
        win.change_property(self._STRUTP, Xatom.CARDINAL, 32, [0, 0, top, bottom,
                                                               0, 0, 0, 0, top_start, top_end, bottom_start, bottom_end])
