#!/usr/bin/env python
import commands
import requests
import json

url = "http://consul1.dx/v1/agent/members"
username = "a"
password = "a"

file = "/etc/hosts"

name_list = []
addr_list = []

def get_host(url, username, password):
    global data
    try:
        response = requests.get(url, auth=(username, password))

        # Consider any status other than 2xx an error
        if not response.status_code // 100 == 2:
            return "Error: Unexpected response {}".format(response)

        data = response.json()
        add_host(data)
        return data

    except requests.exceptions.RequestException as e:
        # A serious problem happened, like an SSLError or InvalidURL
        return "Error: {}".format(e)
        return data

def add_host(data):
    commands.getoutput('sed -i /#fHost/,/#lHost/d ' + file)
    space = commands.getoutput('tail -n1 ' + file).split()

    f = open(file,"ar")

    if len(space) != 0:
        f.write("\n")

    f.write("#fHost")
    for item in data:
        if item['Status'] == 1:
            name_list.append(item['Name'])
            addr_list.append(item['Addr'])
            f.write("\n" + item['Addr'] + " " + item['Name'])

    f.write("\n#lHost")
    f.close()

get_host(url, username, password)