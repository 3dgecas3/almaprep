#!/bin/bash

# Check if the script is being run by setup.sh
if [ -z "$LOG_FILE" ]; then
  echo "Error: This script should be run via setup.sh"
  exit 1
fi

# helper functions for ssh key management
get_ssh_key() {
  read -r -p "Please supply the public ssh key for user "$1": " ssh_key
  echo "$ssh_key" > /home/"$1"/.ssh/authorized_keys
  chown "$1":"$1" /home/"$1"/.ssh/authorized_keys
  chmod 600 /home/"$1"/.ssh/authorized_keys
  logging "Added ssh key for user '$1'" 
}
make_ssh_key() {
  read -r -s -p "Enter a passphrase for the SSH key (leave empty for no passphrase): " passphrase
  echo
  if [ -z "$passphrase" ]; then
    ssh-keygen -t ed25519 -f /home/"$1"/.ssh/id_ed25519 -N ""
  else
    ssh-keygen -t ed25519 -f /home/"$1"/.ssh/id_ed25519 -N "$passphrase"
  fi
  cat /home/"$1"/.ssh/id_ed25519.pub > /home/"$1"/.ssh/authorized_keys
  chown "$1":"$1" /home/"$1"/.ssh/id_ed25519 /home/"$1"/.ssh/id_ed25519.pub /home/"$1"/.ssh/authorized_keys
  chmod 600 /home/"$1"/.ssh/id_ed25519 /home/"$1"/.ssh/id_ed25519.pub /home/"$1"/.ssh/authorized_keys
  logging "Generated and added ssh key for user '$1'"
  echo "The private key is located at /home/$1/.ssh/id_ed25519"
  echo "The public key is located at /home/$1/.ssh/id_ed25519.pub"
}

# Get or make ssh key for user, takes username as argument
user_ssh() {
  if [ ! -s /home/"$1"/.ssh/authorized_keys ]; then
    mkdir -p /home/"$1"/.ssh
    chown "$1":"$1" /home/"$1"/.ssh
    chmod 700 /home/"$1"/.ssh
    read -p "Would you like to supply an ssh key for user '$1'? y/n " yn
    case "$yn" in
      [Yy]* ) get_ssh_key "$1";;
      [Nn]* ) make_ssh_key "$1";;
      * ) echo "Please answer with a Y or an N.";;
    esac
  fi
}

# Helper function for changing the ssh port
change_ssh_port() {
  read -p "What port would you like to use for ssh? " ssh_port
  sed -i "s/#Port 22/Port '$ssh_port'/" /etc/ssh/sshd_config
  systemctl restart sshd
  logging "Changed ssh port to '$ssh_port'"
}

ufw_delete_allowed_ports() {
  local rules=()
  ufw status numbered | awk -F"[][]" '/ALLOW/ {print $1 $2 $3 $4}' | while read -r num dest action from; do
    rules+=("$num")
    echo "Deleting rule $num: $dest $action $from"
    logging "Deleting rule $num: $dest $action $from"
  done
  for ((i=${#rules[@]}-1; i>=0; i--)); do
    echo y | ufw delete "${rules[i]}"
  done
}

# Looping function to check install and status of ufw
check_ufw() {
  echo y | ufw enable
  ufw_delete_allowed_ports
  echo "ufw is installed and enabled"
  logging "ufw is installed and enabled"
  sed -i 's|#net/ipv6/conf/default/autoconf=0|net/ipv6/conf/default/autoconf=0|' /etc/ufw/sysctl.conf
  sed -i 's|#net/ipv6/conf/all/autoconf=0|net/ipv6/conf/all/autoconf=0|' /etc/ufw/sysctl.conf
  sed -i 's|IPV6=yes|IPV6=no|' /etc/default/ufw
  ufw reload
  ufw allow "$ssh_port"/tcp 
  echo "ufw is allowing port '$ssh_port'/tcp"
  logging "ufw is allowing port '$ssh_port'/tcp"
}

# Function to make knockd config
make_knockd_config() {
    echo "Knockd uses sequences of the form port:proto seperated by commas."
    read -p "Please supply the knock sequence to open the ssh port: " open_sequence
    read -p "Please supply the knock sequence to close the ssh port: " close_sequence
    cat <<EOF > /etc/knockd.conf
    [options]
        UseSyslog

    [openPORT]
        sequence      = "$open_sequence"
        seq_timeout   = 15
        command       = ufw allow "$ssh_port"
    [closePORT]
        sequence      = "$close_sequence"
        seq_timeout   = 15
        command       = ufw delete allow "$ssh_port"
EOF
    logging "knockd config created, the open sequence is "$open_sequence" and the close sequence is $close_sequence"
    logging "knockd is altering the ufw firewall rule for port '$ssh_port'"
}

check_knockd() {
    if ! dnf list installed knock-server; then
        echo "knockd is not installed."
        read -p "Would you like to implement knockd? y/n " yn
        case "$yn" in
        [Yy]* ) dnf -y install knock-server;
        make_knockd_config;
        systemctl enable knockd;
        logging "knockd is enabled";;
        [Nn]* ) logging "knockd was not enabled.";;
        * ) echo "Please answer with a Y or an N.";;
        esac
    fi
}

# Secure ssh
user_ssh "$admin_username"
user_ssh "$second_username"
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
read -p "Would you like to change the ssh port? y/n " yn
case "$yn" in
  [Yy]* ) change_ssh_port;;
  [Nn]* ) logging "Did not change ssh port";;
  * ) echo "Please answer with a Y or an N.";;
esac
systemctl restart sshd
check_ufw
check_knockd
logging "Secured ssh"