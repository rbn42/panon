#!/bin/bash

#Verify the existence of third party files before packaging.
if [ -f "third_party/hsluv-glsl/hsluv-glsl.fsh" ];then

    # plasmoid
    rm ./plasmoid/contents/scripts/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/*/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/*/*/__pycache__/ -r
    rm ./panon.plasmoid
    zip -r panon.plasmoid ./plasmoid 

    # i18n
    cd ./translations
    mkdir build
    cd build 
    cmake ..
    rm ./locale -r
    make install DESTDIR=./locale
    cd locale
    NAME=../../../i18n.tgz
    rm $NAME
    tar czvf $NAME *
    # Extract
    # tar xzvf $NAME -C ~/.local/share/locale

else
    echo "Cannot find third party files."
fi
