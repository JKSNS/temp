#!/bin/bash

# Global variable for the package manager
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
  # Detect the OS/package manager first.
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

  # Clone the vulscan repository if it isn't already present.
  if [ -d "scipag_vulscan" ]; then
    echo "[*] 'scipag_vulscan' directory already exists. Skipping clone."
  else
    echo "[*] Cloning vulscan repository..."
    git clone https://github.com/scipag/vulscan scipag_vulscan
  fi

  # Download cve.csv.tar.gz if not already downloaded.
  if [ -f "cve.csv.tar.gz" ]; then
    echo "[*] 'cve.csv.tar.gz' already exists. Skipping download."
  else
    echo "[*] Downloading cve.csv archive..."
    wget https://raw.githubusercontent.com/BYU-CCDC/public-ccdc-resources/main/linux/cve.csv.tar.gz
  fi

  # Extract cve.csv if it does not exist.
  if [ -f "cve.csv" ]; then
    echo "[*] 'cve.csv' already exists. Skipping extraction."
  else
    echo "[*] Extracting cve.csv archive..."
    tar -xzvf cve.csv.tar.gz
  fi

  # Copy vulscan files into Nmap's script directory if not already present.
  if [ -d "/usr/share/nmap/scripts/vulscan" ]; then
    echo "[*] '/usr/share/nmap/scripts/vulscan' already exists. Skipping file copy."
  else
    echo "[*] Copying vulscan files..."
    sudo cp -r ./scipag_vulscan /usr/share/nmap/scripts/vulscan
    sudo cp cve.csv /usr/share/nmap/scripts/vulscan/cve.csv
  fi
}

scan_hosts() {
  # Get a human-readable timestamp (e.g. 2025-01-31_14-30-15)
  timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  resultdir="individual-vulscan-results-$timestamp"
  mkdir "$resultdir"

  echo "[*] Scanning hosts from file: $1"
  # Process each line in the provided hosts file.
  while IFS= read -r line || [[ -n "$line" ]]; do
      echo "[*] Scanning $line..."
      nmap -sV --script=vulscan/vulscan.nse --script-args "vulscandb=cve.csv, vulscanoutput='{id} | {product} | {version} | {title}\n'" "$line" > "$resultdir/results-$line.txt"
  done < "$1"

  # Combine all individual scan results into a single file.
  cat "$resultdir"/* > "complete-vulscan-result.txt"
  echo "[*] Combined scan results saved in 'complete-vulscan-result.txt'"
}

print_options() {
  echo "
Usage: $0 [OPTION] [HOSTS FILE]

Options:
  full      Sets up scanning utilities and scans using the hosts file.
  setup     Sets up scanning utilities without scanning.
  scan      Scans using the hosts file.
  help      Displays this help message.

Note: The HOSTS FILE is required for the 'full' and 'scan' options. The file should contain one scannable entry (URL, IP Address, CIDR, etc.) per line.
"
}

# Ensure at least one argument is provided.
if [ $# -lt 1 ]; then
  print_options
  exit 1
fi

# Parse command-line options.
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
