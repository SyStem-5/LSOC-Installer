#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

echo -e "\e[1m\e[45mSSH Setup\e[0m: Installing SSH..."
apt -y install ssh

# Prepare the folder structure for ssh
mkdir -p /root/.ssh

############TEMPORARY############
echo -e "\e[1m\e[45mSSH Setup\e[0m: WHEN NEUS BECOMES STABLE -> THIS NEEDS TO BE REMOVED!"

echo -e "\e[1m\e[45mSSH Setup\e[0m: Writing settings file & setting permissions..."
echo \
"Port 39901
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
PrintMotd no
Subsystem	sftp	/usr/lib/ssh/sftp-server" \
> /etc/ssh/sshd_config && chmod 644 /etc/ssh/sshd_config

echo -e "\e[1m\e[45mSSH Setup\e[0m: [TEMPORARY] Adding public key for maintenance & setting permissions..."
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOsn3flMwM3MGoCRGuQZZVy4vpU+oRgIgmkl8TEZUKce root@system-pc" \
> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && chmod 700 /root/.ssh
############TEMPORARY############

echo -e "\e[1m\e[45mSSH Setup\e[0m: Restarting SSH daemon..."
systemctl restart sshd
