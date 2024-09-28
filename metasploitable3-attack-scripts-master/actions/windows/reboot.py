from utils import Action

class Reboot(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Reboot the system',
            description='',
            requirements=[],
            webserver=False,
            server_ip=server_ip,
            scriptname='reboot.ps1',
            print_output=False
        )
