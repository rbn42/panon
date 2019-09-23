![](../../wiki/screenshot.png)

[Previews](../../wiki/Previews).

Dependencies
==
python-numpy python-pyaudio python-websockets qt5-websockets qt5-3d 

Installation
===========
```
python setup.py install --user
cd kde
kpackagetool5 -t Plasma/Applet --install plasmoid
```

Running
===
Start panon server.
```
python -m panon.server
```
Drag panon widget to your panel.
![](../../wiki/plasma-widget1.png)
![](../../wiki/plasma-widget2.png)

Credits
======
Some code parts are adapted from [PyVisualizer](https://github.com/ajalt/PyVisualizer).
