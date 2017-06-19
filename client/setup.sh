#!/bin/bash
setHostname() {
	oldhost=$(cat /etc/hostname)
	echo "Existing hostname is $oldhost"

	urandom="$(cat /dev/urandom | tr -dc A-Z0-9|head -c5 | tr '[:upper:]' '[:lower:]')"
	newhost="$(ifconfig | grep wlan0 | awk '{print $NF}' | sed 's/://g' | tr '[:upper:]' '[:lower:]')$urandom"

	# change hostname in /etc/hosts & /etc/hostname
	sed -i "s/$oldhost/$newhost/g" /etc/hosts
	sed -i "s/$oldhost/$newhost/g" /etc/hostname
  hostname -F /etc/hostname
	echo "New hostname set to $newhost"
}

# Set hostname
if [[ $EUID -ne 0 ]]; then
	echo "You must be a root user" 2>&1
	exit 1
else
  setHostname
fi

