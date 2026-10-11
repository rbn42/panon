#!/bin/bash

if [ -f "third_party/hsluv-glsl/hsluv-glsl.fsh" ];then
    kpackagetool6 -t Plasma/Applet --upgrade plasmoid 2>/dev/null || kpackagetool6 -t Plasma/Applet --install plasmoid
else
    echo "Cannot find third party files. Please execute: git submodule update --init"
fi
