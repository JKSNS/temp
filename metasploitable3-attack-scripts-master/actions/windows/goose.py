from utils import Action

class Goose(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Install desktop goose',
            description='',
            requirements=['SYSTEM'],
            webserver=True,
            server_ip=server_ip,
            scriptname='goose.ps1',
            print_output=False
        )

    def get_kwargs(self):
        return {'server_ip': self.server_ip}