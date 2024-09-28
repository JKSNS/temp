from utils import Action

class SystemSliver(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Create SYSTEM-level sliver scheduled task',
            description='',
            requirements=['SYSTEM'],
            webserver=True,
            server_ip=server_ip,
            scriptname='system_sliver.ps1',
            print_output=True
        )

    def get_kwargs(self):
        return {'server_ip': self.server_ip}