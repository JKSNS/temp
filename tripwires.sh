#!/bin/bash

set_alias() {
    local alias_command=$1
    local new_command=$2
    local rc_file=$3

    echo "alias $alias_command='$new_command'" >> "$rc_file"
    echo "Set alias for $alias_command to execute $new_command in $rc_file."
}

create_fake_binary() {
    local binary_path=$1
    local fake_command=$2

    echo "#!/bin/bash" | sudo tee "$binary_path" > /dev/null
    echo "$fake_command" | sudo tee -a "$binary_path" > /dev/null
    sudo chmod +x "$binary_path"
    echo "Created fake binary at $binary_path that runs '$fake_command'."
}

add_background_process() {
    local command_to_monitor=$1
    local action_on_trigger=$2
    local rc_file=$3

    echo "trap '$action_on_trigger' DEBUG" >> "$rc_file"
    echo "Added background process to monitor '$command_to_monitor' and trigger action in $rc_file."
}

setup_tripwires() {
    # Set aliases for common commands with unexpected behavior
    set_alias "ls" "cowsay 'Unauthorized Access Detected!'" "$HOME/.bashrc"
    set_alias "cat" "rev" "$HOME/.bashrc"
    set_alias "nano" "echo 'Nano is disabled!' && sleep 2 && exit 1" "$HOME/.bashrc"

    # Create fake binaries for common network tools
    create_fake_binary "/usr/local/bin/curl" "echo 'curl is not allowed!' && logger 'curl command used' && sleep 2 && exit 1"
    create_fake_binary "/usr/local/bin/wget" "echo 'wget is restricted!' && logger 'wget command used' && sleep 2 && exit 1"

    # Create a "fake" ls that prints a warning and runs a command
    create_fake_binary "/usr/local/bin/ls" "echo 'Warning: ls is monitored!' && /bin/ls \"\$@\""

    # Add background monitoring processes
    add_background_process "ls" "echo 'ls command was executed by user $USER' | logger" "$HOME/.bashrc"
    add_background_process "cat" "echo 'cat command was executed' | logger" "$HOME/.bashrc"

    # Add tripwires to /etc/bash.bashrc for all users
    sudo bash -c "echo 'alias ls=\"cowsay -f tux \\\"Suspicious activity detected!\\\"\"' >> /etc/bash.bashrc"
    sudo bash -c "echo 'trap \"echo \\\"User \\\$USER used the cd command!\\\" | logger\" DEBUG' >> /etc/bash.bashrc"

    # Reload .bashrc to apply changes
    source "$HOME/.bashrc"
}

main() {
    setup_tripwires
    echo "Tripwires have been set up on the system. Reload your terminal or run 'source ~/.bashrc' to apply changes."
}

main
