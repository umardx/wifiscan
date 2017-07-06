#/bin/bash
[[ `id -u` -eq 0 ]] || { echo "Must be root to run script"; exit 1; }
SSID="WiFiScan"
PASS="KolakSegarMantap"

echo "The following existing configuration will be replaced and modified:"
echo "- /etc/network/interfaces"
echo "- /etc/hostapd/hostapd.conf"
while true; do
    read -p "$* [y/n]: " yn
    case $yn in
        [Yy]*) break  ;;  
        [Nn]*) echo "Aborted" ; exit 1 ;;
    esac
done

echo "[ENTER] SSID (default:${SSID}):"
read TSSID
echo "[ENTER] Password (default:${PASS}):"
read TPASS

if [ ${#TSSID} != "0" ]; then
	SSID="${TSSID}"
fi

if [ ${#TPASS} != "0" ]; then
	PASS="${TPASS}"
fi

sudo apt-get install -y bridge-utils hostapd
sudo sed -i 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf

# Create configuration network interfaces
cat <<'EOF' > ./interfaces
auto lo
iface lo inet loopback

# Disable eth0 / wlan0 config, handled by bridge
auto eth0
iface eth0 inet manual

allow-hotplug wlan0
iface wlan0 inet manual

# Create a bridge with static IP
auto br0
iface br0 inet dhcp
    bridge_ports eth0
EOF

sudo mv ./interfaces /etc/network/interfaces

# Create configuration hotapd.conf
cat <<'EOF' > ./hostapd.conf
# First part is about configuring the access point and is copied from reference 1
interface=wlan0
driver=nl80211
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
# This part is about setting SSID and WPA2 password
ssid=$SSID
wpa_passphrase=$PASS
# This line ask hostapd to add wlan0 to the bridge br0
bridge=br0
EOF
sed -i "s|ssid.*|ssid=$SSID|g" ./hostapd.conf
sed -i "s|wpa_passphrase.*|wpa_passphrase=$PASS|g" ./hostapd.conf
sudo mv ./hostapd.conf /etc/hostapd/hostapd.conf

sed -i '/#DAEMON_CONF=""/c\DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd

echo "========================="
echo "WiFi Configuration done!"
echo "SSID : ${SSID}"
echo "Password : ${PASS}"
echo "Please reboot!"
echo "========================="