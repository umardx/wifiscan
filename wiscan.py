#!/usr/bin/env python
from elasticsearch import Elasticsearch
import datetime
import socket
import fcntl
import struct
import json
import time
import sys
import re

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

chan_list = []
freq_list = []
sign_list = []
ssid_list = []
maca_list = []
qual_list = []
encr_list = []
mode_list = []
beac_list = []

chel_re = re.compile(r'Cell ([0-9]{2})')                    # Cell number

chan_re = re.compile(r'Channel:([0-9]{1,2})')               # Channel
freq_re = re.compile(r'Frequency:([0-9.]{5})')              # Frequency (GHz)
sign_re = re.compile(r'Signal level=([0-9-]{3})')           # Signal Level (dBm)
qual_re = re.compile(r'Quality=([0-9]{2})')                 # Quality (/70)
ssid_re = re.compile(r'ESSID:\"(.*?)\"')                    # SSID
encr_re = re.compile(r'Encryption key:([a-z]{2,3})')        # Encryption (on/off)
mode_re = re.compile(r'Mode:([a-zA-Z-]{1,20})')             # Mode (Master, Ad-Hoc, etc)
maca_re = re.compile(r'Address: ((?:[0-9a-fA-F]:?){12})')   # MAC Address
beac_re = re.compile(r'Last beacon: ([0-9]{1,5})')          # Last Beacon (ms ago)

for line in sys.stdin:
    chan_match = chan_re.match(line)
    chan = chan_re.search(line)
    if ( chan ):
        chan_list.append(int(chan.group(1)))

    qual_match = qual_re.match(line)
    qual = qual_re.search(line)
    if ( qual ):
        qual_list.append(int(qual.group(1)))

    freq_match = freq_re.match(line)
    freq = freq_re.search(line)
    if ( freq ):
        freq_list.append(float(freq.group(1)))

    sign_match = sign_re.match(line)
    sign = sign_re.search(line)
    if ( sign ):
        sign_list.append(int(sign.group(1)))

    ssid_match = ssid_re.match(line)
    ssid = ssid_re.search(line)
    if ( ssid ):
        ssid_list.append(ssid.group(1))

    encr_match = encr_re.match(line)
    encr = encr_re.search(line)
    if ( encr ):
        encr_list.append(encr.group(1))

    mode_match = mode_re.match(line)
    mode = mode_re.search(line)
    if ( mode ):
        mode_list.append(mode.group(1))

    maca_match = maca_re.match(line)
    maca = maca_re.search(line)
    if ( maca ):
        maca_list.append(maca.group(1))

    beac_match = beac_re.match(line)
    beac = beac_re.search(line)
    if ( beac ):
        beac_list.append(int(beac.group(1)))

index = "wifiscan-" + time.strftime("%Y.%m.%d")
ts = datetime.datetime.now()
ip = get_ip_address("wlan0")
hn = socket.gethostname()

data = {
'Timestamp': ts,
'Hostname': hn,
'Address': ip,
}

es = Elasticsearch(timeout=480)
for i in range(0,(len(ssid_list))):
    data.update({
        'SSID':ssid_list[i],
        'Encryption':encr_list[i],
        'MAC Address':maca_list[i],
        'Channel':chan_list[i],
        'Mode':mode_list[i],
        'Frequency (GHz)':freq_list[i],
        'Signal (dBm)':sign_list[i],
        'Quality (70)':qual_list[i],
        'Last Beacon (ms ago)':beac_list[i]
    })
    res = es.index(index=index, doc_type='scanlog', body=data)