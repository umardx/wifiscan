#!/bin/bash

echo $$ > /var/run/watchconsul.pid

[ -f /var/consul/oldip.tmp ] || touch /var/consul/oldip.tmp

consul_setup() {

  newip=$(/sbin/ifconfig wlan00 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
  oldip=$(/bin/cat /var/consul/oldip.tmp)

  if [ "$oldip" != "$newip" ] || ( ! /bin/systemctl status consul > /dev/null 2>&1 ); then
     echo "GANTI $oldip ke $newip" >> /root/gantiip.log
     /usr/local/bin/consul leave > /dev/null 2>&1 &&
     /bin/systemctl restart consul.service > /dev/null 2>&1 &&
     echo "$newip" > /var/consul/oldip.tmp
     echo "$oldip -> $newip : Consul Restarted."
  fi
}

while [ true ]; do
  consul_setup && sleep 1
done
