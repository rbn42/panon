#!/bin/bash
echo Make sure you are playing music when run this script.
echo You are expected to see a colorful image.

port=26532
python3 ./test_websocket_server.py $port  &
cd ../
python3 -m panon.client $port 

echo Make sure you are playing music when run this script.
echo You are expected to see a colorful image.
