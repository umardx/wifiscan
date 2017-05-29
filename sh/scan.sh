#!/bin/bash
#set -x

# Check disk space
diskUse=$( df -H | grep root | awk '{ print $5}' | cut -d'%' -f1 )

while(( $diskUse < 80 )) # limit disk use under 30%
do
  diskUse=$(df -H | grep root | awk '{ print $5}' | cut -d'%' -f1)
  echo "Disk Use" $diskUse "%"
  #./aplist.sh
  #sleep 5    # for command and control
done
