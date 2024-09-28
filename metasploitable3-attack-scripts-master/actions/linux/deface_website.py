from utils import Action

class DefaceWebsite(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Deface website',
            description='',
            requirements=['www-data'],
            webserver=False,
            server_ip=server_ip,
            scriptname='deface_website.sh',
            print_output=False
        )
