#!/bin/bash
dev="wlan0"

echo $$ > /var/run/watchconsul.pid

[ -f /var/consul/oldip.tmp ] || touch /var/consul/oldip.tmp

consul_setup() {
  newip=$(/sbin/ifconfig wlan0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
  oldip=$(/bin/cat /var/consul/oldip.tmp)

  if [ "$oldip" != "$newip" ] && ( /bin/systemctl status consul > /dev/null 2>&1 ) && [ "$newip" != "" ]; then
     /usr/local/bin/consul leave > /dev/null 2>&1 &&
     /bin/systemctl restart consul.service > /dev/null 2>&1 &&
     echo "$newip" > /var/consul/oldip.tmp
     echo "$oldip -> $newip : Consul Restarted."
  fi
}

wifi_setup() {
  if (/sbin/ifconfig $dev | grep "inet addr" >/dev/null 2>&1) && (nc -vz 8.8.8.8 53 >/dev/null 2>&1); then
    :
  else
    echo "Restart networking"
    /bin/systemctl restart networking > /dev/null 2>&1 && /sbin/dhclient $dev > /dev/null 2>&1
    sleep 10
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
  wifi_setup
  consul_setup
  sleep 5
done
