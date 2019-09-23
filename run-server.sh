#!/bin/bash
wid=$(pgrep -a python | grep panon.server | cut -d" " -f1)
echo $wid
kill $wid

cd "$(dirname "$0")"
python -m panon.server
