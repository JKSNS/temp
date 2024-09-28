from utils import Action

class Linpeas(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Run linpeas',
            description='',
            requirements=[],
            webserver=False,
            server_ip=server_ip,
            scriptname='linpeas.sh',
            print_output=True
        )
