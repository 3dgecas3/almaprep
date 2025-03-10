#!/bin/bash

# Check if the script is being run by setup.sh
if [ -z "$LOG_FILE" ]; then
  echo "Error: This script should be run via setup.sh"
  exit 1
fi

# Installs podman and podman-compose
install_podman() {
  dnf -y install podman podman-compose podman-docker container-tools
  logging "podman installed"
}

# Installs dependencies for rootless podman
install_rootless() {
  dnf -y install slirp4netns fuse-overlayfs passt
  logging "rootless podman dependencies installed"
}

# Checks and adds subuid and subgid, takes username and file as arguments
add_sub() {
  if [ ! -s "$2" ]; then
    echo "'$1':100000:65536" >> "$2"
    logging "added '$1' to '$2'" 
  elif ! grep -q "$1" "$2" && ! grep -q "100000:65536" "$2"; then
    echo "'$1':100000:65536" >> "$2"
    logging "added '$1' to '$2'"
  elif ! grep -q "$1" "$2" && grep -q "100000:65536" "$2" && ! grep -q "165536:65536" "$2"; then
    echo "'$1':165536:65536" >> "$2"
    logging "added '$1' to '$2'"
  else
    echo "'$1' already in '$2'"
    logging "$(cat "$2")"
  fi
}

install_rootless
add_sub "$admin_username" /etc/subuid
add_sub "$admin_username" /etc/subgid
add_sub "$second_username" /etc/subuid
add_sub "$second_username" /etc/subgid
install_podman
logging "podman setup complete"