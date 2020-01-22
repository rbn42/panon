#!/bin/bash

#Verify the existence of third party files before packaging.
if [ -f "../third_party/hsluv-glsl/hsluv-glsl.fsh" ];then

    rm ../panon/__pycache__ -r
    rm ./plasmoid/contents/scripts/__pycache__/ -r
    rm ./plasmoid/contents/scripts/soundcard/__pycache__/ -r
    rm ./panon.plasmoid
    zip -r panon.plasmoid ./plasmoid 

else
    echo "Cannot find third party files."
fi
