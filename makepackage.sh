#!/bin/bash

#Verify the existence of third party files before packaging.
if [ -f "third_party/hsluv-glsl/hsluv-glsl.fsh" ];then

    # Remove caches
    rm ./plasmoid/contents/scripts/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/*/__pycache__/ -r
    rm ./plasmoid/contents/scripts/*/*/*/__pycache__/ -r
    rm ./panon.plasmoid

    # i18n
    mkdir build
    cd build 
    cmake ../translations
    make install DESTDIR=../plasmoid/contents/locale
    cd ..

    zip -r panon.plasmoid ./plasmoid 

else
    echo "Cannot find third party files."
fi
