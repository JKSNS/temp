#!/bin/bash
wget https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -O /tmp/linpeas.sh
chmod +x /tmp/linpeas.sh
/tmp/linpeas.sh -a > /tmp/out.txt