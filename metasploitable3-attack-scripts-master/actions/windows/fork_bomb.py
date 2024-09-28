from utils import Action

class ForkBomb(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Run a fork bomb (this will hang)',
            description='',
            requirements=[],
            webserver=False,
            server_ip=server_ip,
            scriptname='fork_bomb.ps1',
            print_output=False
        )
