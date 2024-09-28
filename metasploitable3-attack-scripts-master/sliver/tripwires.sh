#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo." 
   exit 1
fi

install_package() {
    local package_name=$1
    if ! dpkg -l | grep -qw "$package_name"; then
        echo "Installing $package_name..."
        sudo apt update
        sudo apt install -y "$package_name"
    else
        echo "$package_name is already installed."
    fi
}

set_alias() {
    local alias_command=$1
    local new_command=$2
    local rc_file=$3

    echo "alias $alias_command='$new_command'" >> "$rc_file"
    echo "Set alias for $alias_command to execute $new_command in $rc_file."
}

create_fake_binary() {
    local original_command=$1
    local fake_command=$2
    local binary_path="/usr/local/bin/$original_command"

    if command -v "$original_command" >/dev/null 2>&1; then
        echo "$original_command binary found. Creating a fake binary at $binary_path."
        echo "#!/bin/bash" | sudo tee "$binary_path" > /dev/null
        echo "$fake_command" | sudo tee -a "$binary_path" > /dev/null
        sudo chmod +x "$binary_path"
        echo "Created fake binary at $binary_path that runs '$fake_command'."
    else
        echo "$original_command binary not found. Skipping creation of fake binary."
    fi
}

add_background_process() {
    local command_to_monitor=$1
    local action_on_trigger=$2
    local rc_file=$3

    echo "trap '$action_on_trigger' DEBUG" >> "$rc_file"
    echo "Added background process to monitor '$command_to_monitor' and trigger action in $rc_file."
}

setup_tripwires() {
    while true; do
        echo "Choose the tripwire setup you would like to implement:"
        echo "1) Alias for ls to print a warning and alias sl to original ls"
        echo "2) Alias for cat to reverse"
        echo "3) Fake binary for curl"
        echo "4) Fake binary for wget"
        echo "5) Background monitor for ls command"
        echo "6) Background monitor for cat command"
        echo "7) System-wide tripwires (modifies /etc/bash.bashrc)"
        echo "q) Quit"
        
        read -r -p "Enter your choices (e.g., 1 2 3): " choice

        case $choice in
            1) 
                install_package "cowsay"
                install_package "sl"
                set_alias "ls" "cowsay 'Unauthorized Access Detected! Use sl for the original ls.'" "$HOME/.bashrc"
                set_alias "sl" "/bin/ls" "$HOME/.bashrc"
                ;;
            2) 
                set_alias "cat" "rev" "$HOME/.bashrc"
                ;;
            3) 
                create_fake_binary "curl" "echo 'curl is not allowed!' && logger 'curl command used' && sleep 2 && exit 1"
                ;;
            4) 
                create_fake_binary "wget" "echo 'wget is restricted!' && logger 'wget command used' && sleep 2 && exit 1"
                ;;
            5) 
                add_background_process "ls" "echo 'ls command was executed by user $USER' | logger" "$HOME/.bashrc"
                ;;
            6) 
                add_background_process "cat" "echo 'cat command was executed' | logger" "$HOME/.bashrc"
                ;;
            7) 
                install_package "cowsay"
                install_package "sl"
                echo "Adding system-wide tripwires to /etc/bash.bashrc..."
                sudo bash -c "echo 'alias ls=\"cowsay -f tux \\\"Suspicious activity detected!\\\"\"' >> /etc/bash.bashrc"
                sudo bash -c "echo 'alias sl=\"/bin/ls\"' >> /etc/bash.bashrc"
                sudo bash -c "echo 'trap \"echo \\\"User \\\$USER used the cd command!\\\" | logger\" DEBUG' >> /etc/bash.bashrc"
                ;;
            q) 
                echo "Exiting setup."
                break
                ;;
            *) 
                echo "Invalid choice: $choice"
                ;;
        esac

        echo "Tripwire setup completed. Choose another option or press 'q' to quit."
    done

    source "$HOME/.bashrc"
    echo "Tripwires have been set up on the system. Reload your terminal or run 'source ~/.bashrc' to apply changes."
}

main() {
    setup_tripwires
}

main
