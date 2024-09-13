#!/bin/bash

check_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "UFW enabled."
        FIREWALL="ufw"
    elif command -v iptables >/dev/null 2>&1; then
        echo "Iptables enabled."
        FIREWALL="iptables"
    else
        echo "No firewall is enabled. Exiting."
        exit 1
    fi
}

block_service() {
    local SERVICE_PORT=$1
    local PROTOCOL=$2

    if [ "$FIREWALL" == "ufw" ]; then
        sudo ufw deny "$SERVICE_PORT/$PROTOCOL"
        echo "Blocked $SERVICE_PORT/$PROTOCOL."
    elif [ "$FIREWALL" == "iptables" ]; then
        sudo iptables -A INPUT -p "$PROTOCOL" --dport "$SERVICE_PORT" -j DROP
        echo "Blocked $SERVICE_PORT/$PROTOCOL."
    fi
}

deface_or_stop_service() {
    local SERVICE=$1

    case $SERVICE in
        "drupal")
            echo "Stopping Drupal service..."
            sudo systemctl stop apache2
            echo "Defacing Drupal website..."
            echo "<h1>Site Defaced!</h1><p>This site has been hacked.</p>" | sudo tee /var/www/html/index.html
            ;;
        "payroll")
            echo "Stopping Payroll website service..."
            sudo systemctl stop apache2
            echo "Defacing Payroll website..."
            echo "<h1>Payroll Site Down!</h1><p>Maintenance in progress.</p>" | sudo tee /var/www/payroll/index.html
            ;;
        "elasticsearch")
            echo "Stopping Elasticsearch service..."
            sudo systemctl stop elasticsearch
            echo "Elasticsearch service stopped."
            ;;
        "wordpress")
            echo "Stopping WordPress service..."
            sudo systemctl stop apache2
            echo "Defacing WordPress site..."
            echo "<h1>WordPress Site Defaced!</h1><p>Unauthorized Access Detected.</p>" | sudo tee /var/www/wordpress/index.html
            ;;
        "rdp")
            echo "Disabling RDP service..."
            sudo systemctl stop xrdp
            echo "RDP service disabled."
            ;;
        "smb")
            echo "Stopping SMB service..."
            sudo systemctl stop smbd
            echo "SMB service stopped."
            ;;
        *)
            echo "Invalid service choice for defacement or stopping."
            ;;
    esac
}

manage_services() {
    echo "Select the services to disable or deface (e.g., 1 2 3 for multiple choices):"
    echo "1) Drupal website (port 80)"
    echo "2) Payroll website app (port 8080)"
    echo "3) FTP service (port 21)"
    echo "4) SSH (port 22)"
    echo "5) IRC (port 6667)"
    echo "6) Metasploitable info page (port 3500)"
    echo "7) Elasticsearch"
    echo "8) RDP"
    echo "9) SMB"
    echo "10) WordPress"

    read -r -p "Enter your choices: " choices

    for choice in $choices; do
        case $choice in
            1) block_service 80 "tcp"; deface_or_stop_service "drupal" ;;   # Drupal 
            2) block_service 8080 "tcp"; deface_or_stop_service "payroll" ;; # Payroll
            3) block_service 21 "tcp" ;;   # FTP 
            4) block_service 22 "tcp" ;;   # SSH
            5) block_service 6667 "tcp" ;; # IRC
            6) block_service 3500 "tcp" ;; # Metasploitable
            7) block_service 9200 "tcp"; deface_or_stop_service "elasticsearch" ;; # Elasticsearch
            8) block_service 3389 "tcp"; deface_or_stop_service "rdp" ;; # RDP
            9) block_service 445 "tcp"; deface_or_stop_service "smb" ;; # SMB
            10) block_service 8585 "tcp"; deface_or_stop_service "wordpress" ;; # WordPress
            *) echo "Invalid choice: $choice" ;;
        esac
    done
}

main() {
    check_firewall
    manage_services
}

main
