from utils import Action

class StopWebsite(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Stop the website on port 80',
            description='',
            requirements=['SYSTEM'],
            webserver=False,
            server_ip=server_ip,
            scriptname='stop_website.ps1',
            print_output=True
        )
