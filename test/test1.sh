#!/bin/bash
echo Make sure you are playing music when run this script.
echo You are expected to see a colorful image.

cd ../
python3 -m panon.server 8765 -1 &

sleep 2
cd -
python3 ./test1.py &

sleep 2
wid=$(pgrep -a python | grep panon.server | cut -d" " -f1)
echo $wid
kill $wid

echo Make sure you are playing music when run this script.
echo You are expected to see a colorful image.
