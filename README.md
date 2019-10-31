
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
Shaders are stored in [kde/plasmoid/contents/shaders/](kde/plasmoid/contents/shaders/). 

Providing panon is installed in your home directory, you can add your own shader files to ```~/.local/share/plasma/plasmoids/panon/contents/shaders/```. The name of the shader file must be ended with ".frag". Panon can detect and load new shaders in this folder during runtime.

Credits
======
Some code parts are adapted from [PyVisualizer](https://github.com/ajalt/PyVisualizer).
