#!/bin/bash

# Check if the current user has root privileges  
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Function to check commands necessary in the scripts
check_requirements() {
  local required_commands=("openssl" "useradd" "groupadd" "chpasswd" "ufw" "ssh-keygen")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' not found"
      exit 1
    fi
  done
}

check_requirements

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

# A for loop to source the scripts
for script in usermanagement.sh sshmanagement.sh setuppodman.sh; do
    if [ -f "$script" ]; then
        source "$script"
    else
        echo "Error: Required script $script not found"
        exit 1
    fi
done

# Tighten permissions on the scripts
chmod 700 ./*.sh