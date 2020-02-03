#!/bin/bash

if [ -f "third_party/hsluv-glsl/hsluv-glsl.fsh" ];then
    plasmoidviewer --applet ./plasmoid/
else
    echo "Cannot find third party files."
fi
