import subprocess
import time
from shells.shell import Shell

class RDPShell(Shell):
    '''Class for interacting with RDP session like a shell'''

    def __init__(self, target: str, os: str, process, window_id: str):
        self.process = process
        self.window_id = window_id
        super().__init__(target, os)
    
    def running(self):
        '''Check if shell is still accessible'''
        return self.process is not None and self.process.poll() is None
    
    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        # For this shell, print_r doesn't do anything, and commands will not hang this function
        if self.running():
            # Assuming cursor is in a PowerShell window, type the command and press "Return"
            subprocess.run(['xdotool', 'type', '--window', self.window_id, cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(['xdotool', 'key', '--window', self.window_id, 'Return'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(3)
            # No way to actually know if it ran but this is the best that can be offered
            return True
        return False

    def kill(self):
        '''Close the shell'''
        for i in range(2):
            # Close both PowerShell windows
            subprocess.run(['xdotool', 'type', '--window', self.window_id, 'exit'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            subprocess.run(['xdotool', 'key', '--window', self.window_id, 'Return'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        # Close RDP window
        subprocess.run(['xdotool', 'windowclose', self.window_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Wait for RDP process to end
        while self.process.poll() is None:
            pass
