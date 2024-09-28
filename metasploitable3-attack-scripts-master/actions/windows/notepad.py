from utils import Action

class Notepad(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Send a notepad message',
            description='',
            requirements=['SYSTEM'],
            webserver=False,
            server_ip=server_ip,
            scriptname='message.ps1',
            print_output=True
        )
    
    def get_kwargs(self):
        message = input('Enter a message: ')
        return {'message': message}