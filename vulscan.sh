#!/bin/bash

# Global variable to store the detected package manager
pm=""

# Function to detect the OS package manager
detect_os() {
  echo "[*] Detecting package manager..."
  if command -v apt-get >/dev/null 2>&1; then
      pm="apt"
  elif command -v dnf >/dev/null 2>&1; then
      pm="dnf"
  elif command -v yum >/dev/null 2>&1; then
      pm="yum"
  elif command -v zypper >/dev/null 2>&1; then
      pm="zypper"
  else
      echo "[X] Error: No supported package manager found."
      exit 1
  fi
  echo "[*] Detected package manager: $pm"
}

setup_scripts() {
  # Detect package manager before installing packages
  detect_os

  echo "[*] Installing required packages..."
  case "$pm" in
    "apt")
      sudo apt update -y
      sudo apt install nmap git -y
      ;;
    "dnf")
      sudo dnf install nmap git -y
      ;;
    "yum")
      sudo yum install nmap git -y
      ;;
    "zypper")
      sudo zypper install -y nmap git
      ;;
  esac

  echo "[*] Cloning vulscan repository..."
  git clone https://github.com/scipag/vulscan scipag_vulscan

  echo "[*] Downloading cve.csv archive..."
  wget https://raw.githubusercontent.com/BYU-CCDC/public-ccdc-resources/main/linux/cve.csv.tar.gz

  echo "[*] Extracting cve.csv archive..."
  tar -xzvf cve.csv.tar.gz

  echo "[*] Installing vulscan scripts..."
  sudo cp -r ./scipag_vulscan /usr/share/nmap/scripts/vulscan
  sudo cp cve.csv /usr/share/nmap/scripts/vulscan/cve.csv
}

scan_hosts() {
  timestamp=$(date +%s)
  resultdir="results${timestamp}"
  mkdir "$resultdir"
  
  # Read each line from the provided hosts file
  while IFS= read -r line || [ -n "$line" ]; do
    echo "Scanning $line..."
    nmap -sV --script=vulscan/vulscan.nse --script-args "vulscandb=cve.csv, vulscanoutput='{id} | {product} | {version} | {title}\n'" "$line" > "$resultdir/results-$line.txt"
  done < "$1"
  
  # Combine all individual scan results into one file
  cat "$resultdir"/* > "completeresult${timestamp}"
}

print_options() {
  echo "
Usage: $0 [OPTION] [HOSTS FILE]

Options:
  full      Sets up scanning utilities and scans using the hosts file.
  setup     Sets up scanning utilities without attempting scans.
  scan      Scans using the hosts file.
  help      Displays this help message.

Note: The HOSTS FILE is a required argument for the full and scan options. The hosts file should have one scannable entry (URL, IP Address, CIDR, etc.) per line.
"
}

# Check if at least one argument was provided
if [ $# -lt 1 ]; then
  print_options
  exit 1
fi

case $1 in
  "full")
    if [ $# -lt 2 ]; then
      print_options
      exit 1
    fi
    setup_scripts 
    scan_hosts "$2"
    ;;
  "setup")
    setup_scripts
    ;;
  "scan")
    if [ $# -lt 2 ]; then
      print_options
      exit 1
    fi
    scan_hosts "$2"
    ;;
  "help")
    print_options
    ;;
  *)
    print_options
    exit 1
    ;;
esac
