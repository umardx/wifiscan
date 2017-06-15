#!/bin/bash

echo $$ > /var/run/watchconsul.pid

[ -f /var/consul/oldip.tmp ] || touch /var/consul/oldip.tmp

consul_setup() {

  newip=$(/sbin/ifconfig wlan0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
  oldip=$(/bin/cat /var/consul/oldip.tmp)

  if [ "$oldip" != "$newip" ] && ( /bin/systemctl status consul > /dev/null 2>&1 ) && [ "$newip" != "" ]; then
     echo "GANTI $oldip ke $newip" >> /root/gantiip.log
     /usr/local/bin/consul leave > /dev/null 2>&1 &&
     /bin/systemctl restart consul.service > /dev/null 2>&1 &&
     echo "$newip" > /var/consul/oldip.tmp
     echo "$oldip -> $newip : Consul Restarted."
  fi
}

setup_wait() {
  up=$(awk '{print $1}' /proc/uptime) && up=${up%.*}

  if [ $up -le 60 ]; then
    continue
  fi
}

while [ true ]; do
  setup_wait
  consul_setup && sleep 1
done
