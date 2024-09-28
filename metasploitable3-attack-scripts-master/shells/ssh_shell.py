from shells.shell import Shell
from fabric import Connection
from paramiko.ssh_exception import SSHException, NoValidConnectionsError

class SSHShell(Shell):
    '''Class for interacting with an SSH session'''

    def __init__(self, target: str, os: str):
        self.c = None
        super().__init__(target, os)
    
    def connect(self, username: str, password: str):
        self.c = Connection(self.target, user=username, connect_kwargs={ 'password': password }, connect_timeout=10)

    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        if self.c:
            try:
                r = self.c.run(cmd, hide=True)
                if print_r:
                    self.print_output(r.stdout)
                return True
            except TimeoutError:
                self.error(self.target, 'Connection to SSH timed out')
                return False
            except (SSHException, NoValidConnectionsError) as e:
                self.error(self.target, f'Exception in SSH connection occurred- {e}')
                return False
            except Exception as e:
                self.error(self.target, f'Unknown error occurred- {e}')
                return False
        else:
            self.error(self.target, 'Connection was not valid')
            return False
    
    def kill(self):
        '''Close the shell'''
        pass