from shells.shell import Shell
import threading
import string
import subprocess
import time
from datetime import datetime
import csv
from pathlib import Path

def sort_ips(ips: set) -> list:
    '''Return numerically sorted list of ips'''
    return sorted(ips, key=lambda ip: tuple(int(part) for part in ip.split('.')))

def combine_ips(ips: set) -> list:
    '''Combines a set of ips into sequential ip ranges (for printing)'''
    ips = sort_ips(ips)
    ip_ranges = []
    for ip in ips:
        if len(ip_ranges):
            base = ip_ranges[-1].split('.')
            second = ip.split('.')
            if base[:3] == second[:3]:
                base_int = int(base[3].split('-')[-1])
                second_int = int(second[3])
                if second_int == base_int + 1:
                    octet = '.' + base[3].split('-')[0] + '-' + str(second_int)
                    ip_ranges[-1] = '.'.join(base[:3]) + octet
                    continue
        ip_ranges.append(ip)
    return ip_ranges

class Hosts:
    '''Class to hold information about the hosts to target'''

    def __init__(self, linux: set, windows: set):
        self.linux: list = self.sort(linux)
        self.windows: list = self.sort(windows)
        self.selected_linux: list = self.linux[:]
        self.selected_windows: list = self.windows[:]
    
    def range(self, ips: list) -> list:
        '''Combines a set of ips into sequential ip ranges (for printing)'''
        ips = self.sort(ips)
        ip_ranges = []
        for ip in ips:
            if len(ip_ranges):
                base = ip_ranges[-1].split('.')
                second = ip.split('.')
                if base[:3] == second[:3]:
                    base_int = int(base[3].split('-')[-1])
                    second_int = int(second[3])
                    if second_int == base_int + 1:
                        octet = '.' + base[3].split('-')[0] + '-' + str(second_int)
                        ip_ranges[-1] = '.'.join(base[:3]) + octet
                        continue
            ip_ranges.append(ip)
        return ip_ranges
    
    def sort(self, ips: list) -> list:
        '''Return numerically sorted list of ips'''
        return sorted(ips, key=lambda ip: tuple(int(part) for part in ip.split('.')))

    def select(self, os: str) -> list:
        while True:
            print(f'Please enter numbers (comma-separated) for the {os.title()} IPs you\'d like to target (ENTER for all):')
            ips = self.linux if os == 'linux' else self.windows
            for i, ip in enumerate(ips):
                n = f'{i + 1}. '.ljust(4, ' ')
                print(f'    {n}{ip}')
            nums = input('> ')
            if nums == '':
                return ips
            try:
                nums = [int(num.strip(' ')) for num in nums.split(',')]
            except ValueError:
                print('ERROR: Please enter a valid number')
                continue
            try:
                selected = [ips[num - 1] for num in nums]
            except IndexError:
                print('ERROR: Please enter a valid number')
                continue
            print('Selecting these IPs:')
            print(' '.join(self.range(selected)))
            print()
            return selected
    
    def prompt(self) -> bool:
        print('Selected linux hosts:', ' '.join(self.range(self.selected_linux)))
        print('Selected windows hosts:', ' '.join(self.range(self.selected_windows)))
        print()
        
        while True:
            print('Select IPs to target:')
            print('    1. Modify selection')
            print('    2. Continue')
            choice = input('> ')
            try:
                choice = int(choice)
            except ValueError:
                print('ERROR: Please enter a valid number')
                continue
            match choice:
                case 1:
                    print()
                    self.selected_linux = self.select('linux')
                    self.selected_windows = self.select('windows')
                    return True
                case 2:
                    print()
                    return False
                case _:
                    print('ERROR: Please enter a valid number')
                    continue

class CSV:
    '''Class for writing to a CSV file'''

    def __init__(self, filename: str, linux_hosts: set, windows_hosts: set):
        self.filename = filename
        # Sort IPs numerically
        self.linux_hosts = self.sort_ips(linux_hosts)
        self.windows_hosts = self.sort_ips(windows_hosts)

        # Create CSV headers if new file
        if not Path(filename).exists():
            with open(filename, mode='w', newline='') as f:
                w = csv.writer(f)
                w.writerows([
                    ['TIME', 'TYPE', 'NAME', 'OS'] + self.linux_hosts + self.windows_hosts
                ])
    
    def sort_ips(self, ips: set) -> list:
        '''Return numerically sorted list of ips'''
        return sort_ips(ips)

    def log(self, _type: str, name: str, os: str, results: dict) -> None:
        '''Create a new row in the CSV file'''
        with open(self.filename, mode='a', newline='') as f:
            w = csv.writer(f)
            values = []
            # For each host, mark it as a success or fail
            if os == 'linux':
                for host in self.linux_hosts:
                    if host in results:
                        values.append(results[host])
                    else:
                        values.append('')
                values = values + [''] * len(self.windows_hosts)
            else:
                for host in self.windows_hosts:
                    if host in results:
                        values.append(results[host])
                    else:
                        values.append('')
                values = [''] * len(self.linux_hosts) + values
            
            # Write new row with results
            w.writerows([
                [datetime.now().strftime("%H:%M:%S"), _type.title(), name, os.title()] + values
            ])

class AttackItem:
    '''Class for items to be printed in a prompt'''
    successes = set()
    lock = threading.Lock()
    type = 'Attack'

    def __init__(self, os: str, name: str, description: str, requirements: list, webserver: bool, server_ip: str):
        self.os = os
        self.name = name
        self.description = description
        self.requirements = requirements
        self.webserver = WebServer() if webserver else None
        self.server_ip = server_ip
    
    def __str__(self) -> str:
        '''Return a string to represent this object'''
        if len(self.requirements) > 0:
            return f'{self.os.title()} - {self.name} (requires {", ".join(self.requirements)})'
        else:
            return f'{self.os.title()} - {self.name}'
    
    def message(self, target: str, message: str) -> None:
        '''Print a message'''
        print(f'[{target}] {message}')

    def error(self, target: str, message: str) -> None:
        '''Print an error message'''
        print(f'[{target}] ERROR: {message}')
    
    def log(self, csv: CSV, targets: list) -> None:
        '''Log results of attack to CSV'''
        results = {}
        for target in targets:
            if target in self.successes:
                results[target] = 1
            else:
                results[target] = 0
        csv.log(self.type, self.name, self.os, results)

    def success(self, ip: str) -> None:
        '''Add an IP to list of successful attacks'''
        with self.lock:
            self.successes.add(ip)

    def set_targets(self, targets: list) -> None:
        '''Set list of targets to attack'''
        self.targets = targets

    def get_kwargs(self) -> dict:
        '''Return user-provided arguments in a dictionary'''
        # Override this method
        pass
    
    def set_variables(self) -> None:
        '''Set additional attack-related variables'''
        # Override this method
        pass
    
    def execute(self) -> list[Shell]:
        '''Perform the attack against multiple targets'''
        # Reset successes, get arguments from user, and set attack-specific variables
        self.successes = set()
        self.kwargs = self.get_kwargs()
        self.set_variables()

        # Start webserver if applicable
        self.webserver.start() if self.webserver else None

        # Create a thread for the attack function on each target
        threads = [ResultThread(target=self.attack, args=(t, )) for t in self.targets]
        # Start threads
        for t in threads:
            t.start()
        
        # Get results of threads
        results = [t.join() for t in threads]
        # Stop webserver if applicable
        self.webserver.stop() if self.webserver else None

        return results
    
    def attack(self, target) -> Shell:
        '''Perform the exploit or action on the target'''
        # Override this method
        pass

class Exploit(AttackItem):
    '''Class to represent an exploit and its data'''
    type = 'Exploit'

    def __init__(self, os: str, name: str, description: str, requirements: str, webserver: bool, server_ip: str):
        super().__init__(
            os,
            name,
            description,
            requirements,
            webserver,
            server_ip
        )

    def attack(self, target: str) -> Shell:
        '''Perform the exploit on the target'''
        # Override this method
        pass

class Action(AttackItem):
    '''Class to represent an action and its data'''
    type = 'Action'

    def __init__(self, os: str, name: str, description: str, requirements: str, webserver: bool, server_ip: str, scriptname: str, print_output: bool):
        self.scriptname = scriptname
        self.print_output = print_output
        super().__init__(
            os,
            name,
            description,
            requirements,
            webserver,
            server_ip
        )
        self.script = None
    
    def set_variables(self) -> None:
        # Open PowerShell or Bash script
        with open(f'actions/{self.os}/{self.scriptname}', 'r') as f:
            # Remove comments, blank lines, and join lines appropriately
            script = f.read()
            script = [line for line in script.split('\n') if not line.startswith('#') and line != '']
            if self.os == 'windows':
                script = ' ; '.join(script)
            else:
                script = '\n'.join(script)
            # Substitute placeholder values with user arguments
            if self.kwargs:
                script = string.Template(script)
                script = script.safe_substitute(self.kwargs)
            self.script = script
    
    def attack(self, target: Shell) -> Shell:
        '''Executes the script in the shell'''
        result = target.cmd(self.script, self.print_output)
        if result:
            self.success(target.target)
            return target

class WebServer:
    '''Class for spinning up a temporary webserver in the payloads directory'''
    process = None

    def __init__(self):
        self.server_cmd = ['python3', '-m', 'http.server', '8000', '--bind', '0.0.0.0']

    def start(self) -> None:
        '''Start the webserver'''
        self.process = subprocess.Popen(self.server_cmd, cwd='payloads')
        time.sleep(1)
    
    def stop(self) -> None:
        '''Stop the webserver'''
        self.process.terminate()
        self.process.wait()

class ResultThread(threading.Thread):
    '''Class for threading a function and returning its result'''
    
    def __init__(self, target, args=()):
        super().__init__(target=target, args=args)
        self._return = None

    def run(self) -> None:
        '''Start the thread'''
        if self._target is not None:
            self._return = self._target(*self._args, **self._kwargs)

    def join(self):
        '''Wait for the thread to end'''
        threading.Thread.join(self)
        return self._return

def prompt(items: list[AttackItem], os='all') -> AttackItem:
    '''Prompt user to pick item from items using a number'''
    while True:
        choices = []
        n = 0
        for item in items:
            n_str = f'{n}. '.ljust(4, ' ')
            if os == 'all':
                print(f'    {n_str}{item}')
                choices.append(item)
                n += 1
            elif item.os == 'all' or item.os == os:
                print(f'    {n_str}{item}')
                choices.append(item)
                n += 1
        choice = input('> ')
        try:
            choice = choices[int(choice)]
        except (ValueError, IndexError):
            print('ERROR: Please enter a valid number')
            continue
        return choice
