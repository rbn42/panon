#!/bin/sh
cd "$(dirname "$0")"
cd ../shaders/
python3 -c "import glob;l=glob.glob('*/')+glob.glob('*.frag');l.sort();[print(n) for n in l]"
