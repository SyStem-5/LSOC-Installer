#!/bin/bash

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Setting up firewall..."

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Denying all incoming network traffic by default"

ufw default deny incoming

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Setting firewall rules..."

#Nginx
ufw allow https
#MQTT Secure
ufw allow 8883/tcp

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Enabling firewall..."

ufw enable
