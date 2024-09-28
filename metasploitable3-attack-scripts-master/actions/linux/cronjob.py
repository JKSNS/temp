from utils import Action

class Cronjob(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Create a cronjob (current user)',
            description='',
            requirements=[],
            webserver=False,
            server_ip=server_ip,
            scriptname='cronjob.sh',
            print_output=False
        )
    
    def get_kwargs(self):
        command = input('Enter a command: ')
        interval = input('Enter an interval (in minutes): ')
        return {'interval': interval, 'command': command}