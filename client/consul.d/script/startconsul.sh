#!/bin/bash
dev="wlan0"
devip=$(/sbin/ifconfig ${dev} | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
if [ ${devip} == "" ]; then
  echo "Can't get an IP for ${dev}, maybe ${dev} down"
  exit 1
fi

# Get 8 last digit cpu id
cpuid="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | tail -c9)"
# Get node name from mac address + cpu id
node="${cpuid}$(ifconfig | grep ${dev} | awk '{print $NF}' | sed 's/://g' | tr '[:upper:]' '[:lower:]')"

# Starting consul agent
/usr/local/bin/consul agent -config-dir=/etc/consul.d/client -bind=${devip} -node=${node} -pid-file=/var/run/consul.pid