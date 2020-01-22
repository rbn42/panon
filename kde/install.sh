#!/bin/bash

if [ -f "../third_party/hsluv-glsl/hsluv-glsl.fsh" ];then
    kpackagetool5 -t Plasma/Applet --install plasmoid
    kpackagetool5 -t Plasma/Applet --upgrade plasmoid
else
    echo "Cannot find third party files."
fi
