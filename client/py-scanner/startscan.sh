#!/bin/bash
#set -x
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
while [[ true ]]; do
	/sbin/iwlist wlan0 scan | $WORKDIR/wiscan.py
	
done
