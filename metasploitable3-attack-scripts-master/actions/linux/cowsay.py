from utils import Action

class Cowsay(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Send a cowsay/wall message',
            description='',
            requirements=['cowsay', 'pls binary'],
            webserver=False,
            server_ip=server_ip,
            scriptname='cowsay.sh',
            print_output=False
        )
    
    def get_kwargs(self):
        animal = input('Enter an animal: ')
        message = input('Enter a message: ')
        return {'animal': animal, 'message': message}