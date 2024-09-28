from utils import Action

class ForkBomb(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Run a fork bomb (this will hang)',
            description='',
            requirements=[],
            webserver=False,
            server_ip=server_ip,
            scriptname='fork_bomb.sh',
            print_output=False
        )
