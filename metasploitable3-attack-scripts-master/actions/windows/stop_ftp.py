from utils import Action

class StopFTP(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='windows',
            name='Stop FTP service',
            description='',
            requirements=['SYSTEM'],
            webserver=False,
            server_ip=server_ip,
            scriptname='stop_ftp.ps1',
            print_output=True
        )
