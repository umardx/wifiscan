#!/bin/bash
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

setWiFiScan() {
	# Install dependency
	# Create infping.service
cat <<'EOF' > $WORKDIR/systemd/wifiscan.service
[Unit]
Description=WiFi Scan
Requires=network-online.target
After=network-online.target

[Service]
Type=idle
User=root
Group=root
Restart=on-failure
ExecStart=$WORKDIR/py-scanner/startscan.sh
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF
	sed -i "s|ExecStart.*|ExecStart=$WORKDIR/py-scanner/startscan.sh|g" $WORKDIR/systemd/wifiscan.service
	mv $WORKDIR/systemd/wifiscan.service /etc/systemd/system/wifiscan.service
	systemctl daemon-reload
	systemctl enable wifiscan.service
	systemctl restart wifiscan.service
}

setHostname() {
	oldhost=$(cat /etc/hostname)
	echo "Existing hostname is $oldhost"

	cpuid="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | tail -c9)"
	newhost="${cpuid}$(ifconfig | grep wlan0 | awk '{print $NF}' | sed 's/://g' | tr '[:upper:]' '[:lower:]')"

	# change hostname in /etc/hosts & /etc/hostname
	sed -i "s/$oldhost/$newhost/g" /etc/hosts
	sed -i "s/$oldhost/$newhost/g" /etc/hostname
	hostname -F /etc/hostname
	echo "New hostname (cpuid+mac) set to $newhost"
}

setConsul() {
	# Install consul arm
	wget -qqO consul.zip "https://releases.hashicorp.com/consul/0.8.5/consul_0.8.5_linux_arm.zip"
	unzip -qqo consul.zip -d /usr/local/bin/
	rm consul.zip
	mkdir -p /etc/consul.d/
	mkdir -p /var/consul

	cp -r $WORKDIR/consul.d/* /etc/consul.d/

	# Add systemd
	cp $WORKDIR/systemd/consul.service /etc/systemd/system/
	cp $WORKDIR/systemd/watchconsul.service /etc/systemd/system/
	systemctl daemon-reload
	systemctl enable consul.service
	systemctl restart consul.service
	systemctl enable watchconsul.service
	systemctl restart watchconsul.service
}

setWPA() {
	# Copying wpa_supplicant configuration
	cp $WORKDIR/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
}
# MAIN
# Set hostname
if [[ $EUID -ne 0 ]]; then
	echo "You must be a root" 2>&1
	exit 1
else
	apt-get -qq update
	apt-get install -yqq wget unzip python-pip
	pip install elasticsearch
	setWPA
	setHostname
	setConsul
	setWiFiScan
fi