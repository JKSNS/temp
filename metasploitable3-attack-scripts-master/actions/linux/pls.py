from utils import Action

class Pls(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Escalate to root and deploy SUID pls/sudo binary',
            description='',
            requirements=[],
            webserver=True,
            server_ip=server_ip,
            scriptname='escalate_create_suid.sh',
            print_output=True
        )

    def get_kwargs(self):
        return {'server_ip': self.server_ip}