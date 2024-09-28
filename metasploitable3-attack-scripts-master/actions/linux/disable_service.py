from utils import Action

class DisableService(Action):
    def __init__(self, server_ip: str):
        super().__init__(
            os='linux',
            name='Stop/disable service',
            description='',
            requirements=['pls binary'],
            webserver=False,
            server_ip=server_ip,
            scriptname='disable_service.sh',
            print_output=False
        )
    
    def get_kwargs(self):
        service_name = input('Enter a service name: ')
        return {'service_name': service_name}