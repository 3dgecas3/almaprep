#!/bin/bash

# Check if the current user has root privileges  
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Tighten permissions on the scripts
chmod 700 ./*.sh

# Define output files
LOG_FILE="/var/log/housekeeping.log"
USERPASS_FILE="/var/secure/userpass.csv"

# Create defined files
touch "$LOG_FILE"
mkdir -p /var/secure
chmod 700 /var/secure
touch "$USERPASS_FILE"
chmod 600 "$USERPASS_FILE"

# logging function 
logging() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - '$1'" >> "$LOG_FILE"
}

update_system() {
  echo "Updating system"
  dnf -y update 2>&1 | while IFS= read -r line
  do 
    echo "$line"
    logging "$line"
  done
  echo "System updated"
}

# Helper function to install necessary packages
install_package() {
  dnf install -y "$1" 2>&1 | while IFS= read -r line; do logging "$line"; done
}

# Function to check commands necessary in the scripts
check_requirements() {
  local required_commands=("openssl" "useradd" "groupadd" "chpasswd" "ufw" "ssh-keygen")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' not found"
      echo "Attempting to install it now"
      install_package "$cmd"
      if [ "$?" -ne 0 ]; then
        echo "Error: Failed to install $cmd"
        exit 1
      fi
    fi
  done
}

update_system
check_requirements

# A for loop to source the scripts
for script in usermanagement.sh sshconfiguration.sh rootlesspodman.sh; do
    if [ -f "$script" ]; then
        source "$script"
    else
        echo "Error: Required script $script not found"
        exit 1
    fi
done