#!/bin/bash
dev="wlan0"

echo $$ > /var/run/watchconsul.pid

[ -f /var/consul/oldip.tmp ] || touch /var/consul/oldip.tmp

consul_setup() {
  newip=$(/sbin/ifconfig wlan0 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1)
  oldip=$(/bin/cat /var/consul/oldip.tmp)

  if [ "$oldip" != "$newip" ] && ( /bin/systemctl status consul > /dev/null 2>&1 ) && [ "$newip" != "" ]; then
     /usr/local/bin/consul leave > /dev/null 2>&1
     /bin/systemctl restart consul.service > /dev/null 2>&1
     echo "$newip" > /var/consul/oldip.tmp
     status="${status}|consul-restart"
     sleep 5
  fi
}

wifi_setup() {
  if (nc -vz 8.8.8.8 53 >/dev/null 2>&1); then
    if [ $(cat /sys/class/net/${dev}/operstate) == "up" ]; then
      if (/sbin/ifconfig $dev | grep "inet addr" >/dev/null 2>&1); then
        :
      else
        /sbin/ifdown ${dev} && /sbin/ifup ${dev} && sleep 8 && status="${status}|ifrestart ${dev}"
      fi
    else
      /sbin/ifup ${dev} && sleep 8 && status="${status}|ifup ${dev}"
    fi
  else
    /sbin/ifdown ${dev} && /sbin/ifup ${dev} && sleep 8 && status="${status}|ifrestart ${dev}"
  fi
}

setup_wait() {
  up=$(awk '{print $1}' /proc/uptime) && up=${up%.*}

  if [ $up -le 60 ]; then
    continue
  fi
}

while [ true ]; do
  status=""
  setup_wait
  wifi_setup
  consul_setup
  if [ ${#status} -ne "0" ]; then
    echo $status
  fi
  sleep 3
done
