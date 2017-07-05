#!/bin/bash
dev="wlan0"
devip=$(/sbin/ifconfig ${dev} | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
if [ ${devip} =="" ]; then
  echo "Can't get an IP for ${dev}, maybe ${dev} down"
  exit 1
fi

cpuid="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | tail -c9)"
newhost="${cpuid}$(ifconfig | grep wlan0 | awk '{print $NF}' | sed 's/://g' | tr '[:upper:]' '[:lower:]')"
/usr/local/bin/consul agent -config-dir=/etc/consul.d/client -bind=${devip} -pid-file=/var/run/consul.pid