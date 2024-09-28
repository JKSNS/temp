# Get an octet range
def ask_octet(label: str):
    while True:
        octet_start = input(f'What is the start of the {label} octet? ')
        try:
            octet_start = int(octet_start)
            break
        except ValueError:
            print('ERROR: Please provide an integer')
    
    while True:
        octet_end = input(f'What is the end of the {label} octet (blank if same)? ')
        try:
            if octet_end == '':
                return [octet_start]
            else:
                octet_end = int(octet_end)
            break
        except ValueError:
            print('ERROR: Please provide an integer')
    
    return [octet_start, octet_end]

# Get ip ranges
def generate_ips(os: str):
    print(f'Please answer the following questions about the {os.title()} targets:')
    octet_ranges = [ask_octet(label) for label in ['first', 'second', 'third', 'fourth']]
    print()

    # Generate ip list based on ranges
    hosts = []
    for i in range(octet_ranges[0][0], octet_ranges[0][-1] + 1):
        for j in range(octet_ranges[1][0], octet_ranges[1][-1] + 1):
            for k in range(octet_ranges[2][0], octet_ranges[2][-1] + 1):
                for l in range(octet_ranges[3][0], octet_ranges[3][-1] + 1):
                    hosts.append(f'{i}.{j}.{k}.{l}')
    return hosts

def create_config(server_ip: str, linux_ips: list, windows_ips: list):
    config = f'server_ip: {server_ip}\n\n'

    config += 'linux:\n'
    for ip in linux_ips:
        config += f'  - {ip}\n'

    config += '\n'

    config += 'windows:\n'
    for ip in windows_ips:
        config += f'  - {ip}\n'
    
    return config

# Get server ip
server_ip = input('What is the ip of the kali server? ')
print()
linux_ips = generate_ips('linux')
windows_ips = generate_ips('windows')
config = create_config(server_ip, linux_ips, windows_ips)

print()
print('Configuration:')
print()
print(config)

choice = input('Overwrite options.yaml (y/N)? ')
if choice == 'y':
    with open('options.yaml', 'w') as f:
        f.write(config)