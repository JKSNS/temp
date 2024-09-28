# Scored Services
This is a 4 hour competition, so give them 30 minutes to take down their own services. That leaves us with 3.5 hours for 12 services.<br>
(3.5\*60)/12 = 17.5 minutes / service

So, plan to take down a service about every 15 minutes.

Methods of take down:
- stop service
- delete files
- break or modify config file
- change file ownership
- firewall rules
- DoS

## Linux
### FTP
Port: 21

**Exploits:**
- ProFTPd mod_copy
    - impact: arbitrary write as `www-data` user (web shell)
    - fix: make web directory read-only

### SSH
Port: 22

**Exploits:**
- Default credentials
    - impact: shell as user(s)
    - fix: change passwords

### Drupal
Port: 80<br>
Path: `drupal/`

**Exploits:**
- Apache Shellshock
    - impact: RCE as `www-data` user
    - fix: `sudo a2disconf cgi-bin && sudo service apache2 reload`
- Drupageddon
    - impact: HTTP Parameter Key/Value SQL Injection exploit
    - fix: Update their Drupal core to version 7.32 or apply the patch

### Payroll App
Port: 80<br>
Path: `payroll_app.php`

**Exploits:**
- Apache Shellshock
    - impact/fix: same as above
- ?

### Metasploitable Info Page
Port: 3500<br>
Path: `/readme`

**Exploits:**
- Ruby Actionpack ERB
    - impact: RCE as `chewbacca` user
    - fix: ?

### IRC
Port : 6697

**Exploits:**
- UnrealIRCd backdoor
    - impact: RCE as `boba_fett` user
    - fix: ?

### Unscored
**Exploits:**
- ?

## Windows
### FTP
Port: 21

**Exploits:**
- FTP DoS
    - impact: crashes and consequently turns off service
    - fix: in services.msc, set FTP Recovery option for "Subsequent failures" to "Restart the Service" (band-aid fix)

### HTTP
Port: 80<br>
Restored from a backup we provide to them

**Exploits:**
- IIS DoS
    - impact: crashes/blue-screens Windows machine
    - fix: ?

### SMB
Port: 445

**Exploits:**
- EternalBlue
    - impact: RCE as `System` account
    - fix: update Windows (specifically, https://catalog.update.microsoft.com/search.aspx?q=kb4012598)

### RDP
Port: 3389

**Exploits:**
- Default credentials
    - impact: RCE as `greedo` user with privilege escalation for RCE as `System` account
    - fix: change passwords

### Wordpress
Port: 8585<br>
Path: `/wordpress/`

**Exploits:**
- WAMP PUT
    - impact: arbitrary write as `Local Service` account (web shell)
    - fix: make web directory read-only

### ElasticSearch
Port: 9200

**Exploits:**
- RCE CVE
    - impact: RCE as `System` account
    - fix: ?

### Unscored
**Exploits:**
- Jenkins
    - impact: RCE as `Local Service` account
    - fix: firewall/turn off Jenkins service
