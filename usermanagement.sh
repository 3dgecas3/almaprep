#!/bin/bash

# Check if the script is being run by setup.sh
if [ -z "$LOG_FILE" ]; then
  echo "Error: This script should be run via setup.sh"
  exit 1
fi

# thank you security stack exchange
# nice password generation, special characters included
generate_password() {
  openssl rand 256 | tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_{|}~' | cut -c -30
}

# Check if user exists, make user if it doesn't
# takes username and password as arguments
make_user() {
  if ! getent passwd "$1" &>/dev/null; then
    echo "User $1 does not exist, adding it now"
    useradd "$1"
    echo "$1:$2" | chpasswd
    logging "Created user $1"
  fi
}

# Check if the primary group for the user exists, create one if it doesn't
make_group() {
  if ! getent group "$1" &>/dev/null; then
    echo "Group $1 does not exist, adding it now"
    groupadd "$1"
    logging "Created primary group $1 for user $1"
  fi
}

# Validate username format
validate_username() {
  local username="$1"
  if [[ ! "$username" =~ ^[a-z][-a-z0-9]*$ ]]; then
    echo "Error: Invalid username format"
    return 1
  fi
  return 0
}

# Add sudo privileges without requiring a password for a specific user
# takes username as argument
addsudo() {
  if [ -f /etc/sudoers.d/"$1" ]; then
    echo "User $1 already has sudo privileges"
  else
    echo "$1        ALL=(ALL)       NOPASSWD: ALL" > /tmp/"$1"
    chmod 440 /tmp/"$1"
    visudo -c -f /tmp/"$1"
    if [ "$?" -eq 0 ]; then
      mv /tmp/"$1" /etc/sudoers.d/"$1"
    else
      echo "Error: Failed to add sudo privileges for user $1"
      rm /tmp/"$1"
      return 1
    fi
    logging "Added sudo privileges for user $1"
  fi
}

# create admin user
read -p "Give a name for the admin user, leave blank to use 'admin': " admin_username
admin_username="${admin_username:-admin}"
if ! validate_username "$admin_username"; then
  exit 1
fi
admin_password="$(generate_password)"
make_user "$admin_username" "$admin_password"
make_group "$admin_username"  # create a group with the same name as the user
addsudo "$admin_username"
echo "'$admin_username','$admin_password'" >> "$USERPASS_FILE"
echo "Admin user '$admin_username' created. See password in '$USERPASS_FILE'"

# create secondary user
read -p "Give a name for a non-wheel user, leave blank to use 'user': " second_username
second_username=${second_username:-user}
if ! validate_username "$admin_username"; then
  exit 1
fi
second_password=$(generate_password)
make_user "$second_username" "$second_password"
make_group "$second_username"
echo "User '$second_username' created."
echo "'$second_username','$second_password'" >> "$USERPASS_FILE"
echo "See password in '$USERPASS_FILE'"