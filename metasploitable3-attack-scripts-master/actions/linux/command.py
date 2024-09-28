from utils import Action

class Command(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Run a command',
            description='',
            requirements=[],
            webserver=True,
            server_ip=server_ip,
            scriptname='cmd.sh',
            print_output=True
        )
    
    def get_kwargs(self):
        command = input('Enter a command: ')
        return {'command': command}