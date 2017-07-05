#!/bin/bash
dev="wlan0"

echo $$ > /var/run/watchconsul.pid

[ -f /var/consul/oldip.tmp ] || touch /var/consul/oldip.tmp

consul_setup() {
  newip=$(/sbin/ifconfig wlan0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
  oldip=$(/bin/cat /var/consul/oldip.tmp)

  if [ "$oldip" != "$newip" ] && ( /bin/systemctl status consul > /dev/null 2>&1 ) && [ "$newip" != "" ]; then
     #echo "GANTI $oldip ke $newip" >> /root/gantiip.log
     /usr/local/bin/consul leave > /dev/null 2>&1 &&
     /bin/systemctl restart consul.service > /dev/null 2>&1 &&
     echo "$newip" > /var/consul/oldip.tmp
     echo "$oldip -> $newip : Consul Restarted."
  fi
}

wifi_setup() {
  if (/sbin/ifconfig $dev | grep "inet addr" >/dev/null 2>&1) && (ping -c1 8.8.8.8 >/dev/null 2>&1); then
    sleep 1
  else
    /bin/systemctl restart networking && /sbin/dhclient $dev && sleep 15
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
  wifi_setup && consul_setup && sleep 1
done
