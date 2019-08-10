#!/bin/bash

cd "$(dirname "$0")"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be ran as root."
   exit 1
fi

echo "Install script for LSOC System."

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Proceed with BlackBox installation? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

bb_main_dir=/etc/BlackBox

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Waiting for package manager to become available..."
while true
do
    sudo dpkg --configure -a
    if [ $? -eq 0 ]; then
        echo -e "\e[1m\e[44mLSOC Installer\e[0m: Package manager \e[32m[OK]\e[0m"
        break
    fi
    sleep 1
done

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Check and install system updates? [Y/n] ' -r
REPLY=${REPLY:-y}
if [[ $REPLY =~ ^[Yy]$ ]]; then

    sudo apt-get update
    sudo apt-get -y dist-upgrade

    echo -e "\e[1m\e[44mLSOC Installer\e[0m: Updating complete."
fi

#In case we already have something in root crontab
read -p $'\e[1m\e[44mLSOC Installer\e[0m: Reset crontab? [Y/n] ' -r
REPLY=${REPLY:-y}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    crontab -r
fi

#rm -rf $bb_main_dir

#Run NECO setup script
./neutron_communicator/install.sh
neco_service_file_name=neutroncommunicator.service

#Run ufw setup script
./ufw/setup.sh

#Install docker
if hash docker 2>/dev/null; then
    echo -e "\e[1m\e[44mLSOC Installer\e[0m: Found Docker installed."
    read -p $'\e[1m\e[44mLSOC Installer\e[0m: Check for a new docker version? [Y/n] ' -r
    REPLY=${REPLY:-y}
    echo    #Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apt -y install docker.io
    fi
else
    echo -e "\e[1m\e[44mLSOC Installer\e[0m: Downloading & Installing the latest Docker version."
    apt -y install docker.io
fi

#Run the PostgreSQL installation
./postgres/install.sh $bb_main_dir

#Run BlackBox setup script
#Run the BlackBox service after install so we can configure the database as soon as possible
./blackbox/install.sh $bb_main_dir --start_service

#Run the Mosquitto Broker installation
./mosquitto/install.sh $bb_main_dir

#Run the Web Interface installation
./web_interface/install.sh $bb_main_dir --self_signed

echo -e "\e[1m\e[45mLSOC Installer\e[0m: Enabling Neutron Communicator service..."
systemctl start $neco_service_file_name

echo -e "\e[1m\e[44mLSOC Installer\e[0m: installation completed."

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Press [ENTER] when you are ready to restart. ' -r

echo "The system is going to restart in 5 seconds to complete the installation. Press [CTRL]+C to abort."
sleep 5
echo "Restarting..."
shutdown -r now
