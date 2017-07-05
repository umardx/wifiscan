#!/bin/bash
WORKDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
setupWiFiScan() {
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
}
setupWiFiScan
