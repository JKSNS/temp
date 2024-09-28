# metasploitable3-attack-scripts

The [attack.py](attack.py) script provides a common interface to attack Linux and Windows metasploitable3 machines. It allows you to choose an attack to perform on all target machines, and then perform an action with the access gained from that exploit. A variety of exploits and actions exist to target different services and ideally be able to get around any defenses the blue team puts up.

The goal for this script is to provide enough access to setup sliver binaries running at the root/system level and other forms of persistence. Then, one or more other red team members can use this persistence to take down blue team services.

See the [services](./SERVICES.md) page for an overview of the scored services and how this script can exploit them.

## Dependencies
### System
```shell
sudo apt update
sudo apt install nmap xsel xdotool rdesktop mktemp
```
(or whatever package manager your system uses)

### Python
You'll probably want to make a virtual environment first:
```shell
python3 -m venv venv
source venv/bin/activate
```

Then, install the requirements:
```shell
pip3 install -r requirements.txt
```

## Usage
Add your target IPs to [options.yaml](./options.yaml). If you created a virtual environment, you'll need to activate it:
```shell
source venv/bin/activate
```

Then, run the main script:
```shell
python3 attack.py
```

## Actions
[Actions](./actions/) are commands that can be run in a shell gained by an exploit. Actions are either Bash (Linux) or PowerShell (Windows) scripts that will be handled appropriately by the type of shell they are being ran in. Actions can be anything permitted by the level of permissions your shell has, whether that is defacing the website or creating rogue users.

This script was written in a way that will allow any action to be performed in any shell from any exploit, barring insufficient privileges to perform said action.

## Exploits
[Exploits](./exploits/) are the method of intial access to the system. Exploits return a shell which can be used to run actions. Exploits target a specific service running on the Metasploitable machine and leverage a vulnerability to gain unauthorized access to the machine. The level of access will depend on the particular exploit.

## Payloads
The [payloads](./payloads/) directory is reserved for files that target computers will need to fetch from the attacking machine. Attacks that utilize this will spin up a temporary webserver to serve files from the payloads directory.

## Shells
[Shells](./shells/) are returned by exploits. There are multiple types of shells, including web shells (uploaded PHP files in the web directory) and reverse shells. If a reverse shell is made, listening port numbers follow the `4###` pattern, with `###` being the last octet of the target's IP address. For example, if targeting the IP `192.168.1.123`, the listening port for a reverse shell corresponding to that target will be `4123`.

Shells are written with a common class structure, allowing them to be accessed in a consistent manner so that any action can be performed on any shell.

## Sliver
See the sliver [README.md](./sliver/README.md).

## References
- https://tremblinguterus.blogspot.com/2020/11/metasploitable-3-ubuntu-walkthrough.html
- https://tremblinguterus.blogspot.com/2020/11/metasploitable-3-windows-walkthrough.html
- https://notes.anggipradana.com/tutorial/metasploitable-3
- https://github.com/j4k0m/CVE-2016-2098
- https://github.com/rapid7/metasploitable3/wiki/Vulnerabilities
- https://github.com/rapid7/metasploitable3/wiki/Configuration
- https://medium.com/@kushalshrestha77/pentesting-metasploitable-3-windows-machine-aa824460947e