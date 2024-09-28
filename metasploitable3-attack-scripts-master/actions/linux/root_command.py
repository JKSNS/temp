from utils import Action

class RootCommand(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Run a command as root',
            description='',
            requirements=['pls binary'],
            webserver=False,
            server_ip=server_ip,
            scriptname='pls_cmd.sh',
            print_output=True
        )
    
    def get_kwargs(self):
        command = input('Enter a command: ')
        return {'command': command}