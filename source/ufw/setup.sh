#!/bin/bash

read -p $'\e[1m\e[45mUFW Setup\e[0m: Set up the Uncomplicated Firewall? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo -e "\e[1m\e[45mUFW Setup\e[0m: Setting up firewall..."

echo -e "\e[1m\e[45mUFW Setup\e[0m: Installing UFW..."
apt -y install ufw

echo -e "\e[1m\e[45mUFW Setup\e[0m: Denying all incoming network traffic."
ufw default deny incoming

echo -e "\e[1m\e[45mUFW Setup\e[0m: Allowing all outgoing network traffic."
ufw default allow outgoing

echo -e "\e[1m\e[45mUFW Setup\e[0m: Setting firewall rules..."
#Nginx
ufw allow https
ufw allow http
#MQTT Secure
ufw allow 8883/tcp
#SSH
ufw allow 39901/tcp

echo -e "\e[1m\e[45mUFW Setup\e[0m: Enabling firewall..."
ufw enable
