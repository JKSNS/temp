from utils import Action

class PersistentSliver(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Deploy persistent root sliver session and beacon',
            description='',
            requirements=['pls binary'],
            webserver=True,
            server_ip=server_ip,
            scriptname='root_sliver.sh',
            print_output=True
        )
    
    def get_kwargs(self):
        return {'server_ip': self.server_ip}
