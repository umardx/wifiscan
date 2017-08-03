#!/bin/bash

# Date format
NOW=$(date +"%F")
NOWT=$(date +"%s")

# Path
PATH="./$NOW"

# Make a directory
if [[ ! -d "$NOW" ]];
then
  /bin/mkdir $NOW
fi

# Output to file
/sbin/iwlist wlan0 scan > ./$NOW/$NOWT
