
A Different Audio Spectrum Analyzer

![](../../wiki/plasmoid/preview.png)

[Previews](../../wiki/Previews).

Dependencies
============
python3 python-numpy python-pillow python-pyaudio python-websockets qt5-websockets qt5-3d 

Installation
============
```
cd kde
kpackagetool5 -t Plasma/Applet --install plasmoid
```

Drag panon widget to your panel (eg. [latte-dock](https://github.com/psifidotos/Latte-Dock)).
![](../../wiki/plasmoid/step1.png)
![](../../wiki/plasmoid/step2.png)

Shaders
=======
Shaders are stored in [kde/plasmoid/contents/shaders/](kde/plasmoid/contents/shaders/). You can add your own shader files to this location, or to ~/.local/share/plasma/plasmoids/panon/contents/shaders/, providing panon is installed there. The name of the shader file must end with ".frag". Panon can detect and load new shaders in this folder during runtime.

Credits
======
Some code parts are adapted from [PyVisualizer](https://github.com/ajalt/PyVisualizer).
