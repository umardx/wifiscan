#!/usr/bin/python
import firebase
import datetime
import json
import sys
import re

url = 'https://wifiscan-8076f.firebaseio.com'

chan_list = []
freq_list = []
sign_list = []
ssid_list = []
maca_list = []

chan_re = re.compile(r'Channel:([0-9]+)')
freq_re = re.compile(r'Frequency:([0-9.]+)')
sign_re = re.compile(r'Signal level=([0-9-]+)')
ssid_re = re.compile(r'ESSID:"(.*?)"')
maca_re = re.compile(r'Address: ([0-9A-Fa-f]+:[0-9A-Fa-f]+:[0-9A-Fa-f]+:[0-9A-Fa-f]+:[0-9A-Fa-f]+:[0-9A-Fa-f]+)')

for line in sys.stdin:
    chan_match = chan_re.match(line)
    chan = chan_re.search(line)
    if ( chan ):
        chan_list.append(int(chan.group(1)))

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

    maca_match = maca_re.match(line)
    maca = maca_re.search(line)
    if ( maca ):
        maca_list.append(maca.group(1))

ts = datetime.datetime.now()
data = {"timestamp":ts}
for i in range(0,(len(ssid_list))):
    data.update({
        i:{
        'SSID':ssid_list[i],
        'MAC':maca_list[i],
        'Channel':chan_list[i],
        'Frequency':freq_list[i],
        'Signal':sign_list[i]
        }
    }
)


firebase = firebase.FirebaseApplication(url, None)

res = firebase.post("/APlist", data)

print maca_list