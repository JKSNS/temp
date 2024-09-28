class Shell:
    '''Superclass for a shell
    This mostly exists for type hinting purposes'''
    target = ''

    def __init__(self, target: str, os: str):
        self.target = target
        self.os = os
    
    def cmd(self, cmd: str, print_r = False) -> bool:
        '''Run a command in the shell'''
        pass

    def message(self, target: str, message: str) -> None:
        '''Print a message'''
        print(f'[{self.target}] {message}')

    def error(self, target: str, message: str) -> None:
        '''Print an error message'''
        print(f'[{self.target}] ERROR: {message}')
    
    def print_output(self, output: str) -> None:
        '''Print the output with formatting'''
        print(f'[{self.target}]\n{output}\n')

    def kill(self) -> None:
        '''Close the shell'''
        pass