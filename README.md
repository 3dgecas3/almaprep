# Simple Server Setup Script for Alma

This project provides a set of scripts to automate the setup and configuration of a server running Alma Linux. The scripts handle user creation, SSH configuration, firewall setup, and Podman installation. The inspirtation comes from working in a cloud environment with no ability to supply a user-data file to cloud init. It assumes starting as root in Alma Linux 9.

## Features

- **User Management**: Create users with secure passwords, set up SSH keys, and configure user groups.
- **SSH Configuration**: Secure SSH by disabling root login and password authentication, and optionally change the SSH port.
- **Firewall Setup**: Install and configure UFW to allow the SSH port and enable the firewall.
- **Podman Installation**: Install Podman and its dependencies for rootless containers.
- **Knockd Configuration**: Optionally install and configure knockd for port knocking.

## Prerequisites

- Alma Linux
- Root privileges

## Recommended

- Change root passwd
- Run `dnf update`
- Reboot after update 

## Usage

1. **Clone the repository**:
    ```
    :~# git clone https://github.com/3dgecas3/almaprep.git
    ```

    ```
    :~# cd almaprep
    ```

2. **Run the setup script**:
    ```
    :~# ./setup.sh
    ```

3. **Follow the prompts** to configure users, SSH, and other settings.

## Script Details

### setup.sh

- Checks for root privileges.
- Verifies required commands are available.
- Defines log and user password files.
- Sources other scripts (`usermanagement.sh`, `sshconfiguration.sh`, `rootlesspodman.sh`).

### usermanagement.sh

- Generates secure passwords.
- Creates users and groups if they do not exist.
- Validates username format.

### sshconfiguration.sh

- Manages SSH keys for users.
- Secures SSH configuration.
- Optionally changes the SSH port.
- Configures UFW and knockd.

### rootlesspodman.sh

- Installs Podman and its dependencies.
- Configures subuid and subgid for rootless containers.

## Acknowledgements

- [User creation script](https://github.com/Iheanacho-ai/User-creation-script/blob/main/create_users.sh)
github.com/Iheanacho-ai/User-creation-script
- [Password security](https://security.stackexchange.com/questions/81976/is-this-a-secure-way-to-generate-passwords-at-the-command-line)
security.stackexchange.com/questions/81976
- [Github Copilot](https://github.com/features/copilot) - All available models were consulted
github.com/features/copilot

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.