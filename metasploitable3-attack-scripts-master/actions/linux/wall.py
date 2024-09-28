from utils import Action

class Wall(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Send a wall message',
            description='',
            requirements=['pls binary'],
            webserver=False,
            server_ip=server_ip,
            scriptname='wall.sh',
            print_output=False
        )
    
    def get_kwargs(self):
        message = input('Enter a message: ')
        return {'message': message}