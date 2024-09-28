from utils import Action

# TODO: why does this hang
class TemporarySliver(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Deploy sliver session (not persistent)',
            description='',
            requirements=[],
            webserver=True,
            server_ip=server_ip,
            scriptname='sliver.sh',
            print_output=True
        )

    def get_kwargs(self):
        return {'server_ip': self.server_ip}