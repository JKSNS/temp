from utils import Action

class RogueUsers(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Create rogue users',
            description='',
            requirements=['pls binary'],
            webserver=False,
            server_ip=server_ip,
            scriptname='rogue_users.sh',
            print_output=False
        )