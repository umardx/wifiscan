#!/bin/bash
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#echo $WORKDIR
setHostname() {
	oldhost=$(cat /etc/hostname)
	echo "Existing hostname is $oldhost"

	cpuid="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | tail -c9)"
	newhost="${cpuid}$(ifconfig | grep wlan0 | awk '{print $NF}' | sed 's/://g' | tr '[:upper:]' '[:lower:]')"

	# change hostname in /etc/hosts & /etc/hostname
	sed -i "s/$oldhost/$newhost/g" /etc/hosts
	sed -i "s/$oldhost/$newhost/g" /etc/hostname
	hostname -F /etc/hostname
	echo "New hostname set to $newhost"
}

setConsul() {
	# Install consul arm64
	apt-get update
	apt-get install -y wget unzip
	wget -O consul.zip "https://releases.hashicorp.com/consul/0.8.5/consul_0.8.5_linux_arm64.zip"
	unzip -qq consul.zip -d /usr/local/bin/
	rm consul.zip
	mkdir -p /etc/consul.d/{client,script}
	mkdir /var/consul

	# Add systemd
	cp $WORKDIR/systemd/consul.service /etc/systemd/system/
	cp $WORKDIR/systemd/watchconsul.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable consul.service
	systemctl start consul.service
	systemctl enable watchconsul.service
	systemctl start watchconsul.service
}

setupWiFi() {
	# Copying wpa_supplicant configuration
	cp $WORKDIR/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
}
# MAIN
# Set hostname
if [[ $EUID -ne 0 ]]; then
	echo "You must be a root" 2>&1
	exit 1
else
	setHostname
	setConsul
fi