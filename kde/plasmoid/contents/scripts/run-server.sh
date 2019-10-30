#!/bin/sh
wid=$(pgrep -a python | grep panon.server | cut -d" " -f1)
echo $wid
kill $wid

cd "$(dirname "$0")"
#port=$1
exec python3 -m panon.server $@
