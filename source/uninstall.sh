#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be ran as root." 
   exit 1
fi

read -p "BlackBox Uninstaller: Are you sure you want to uninstall BlackBox? [Y/N] " -r
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

lib_loc=/usr/local/lib/
bb_bin_loc=/bin/black_box
bb_config_loc=/etc/BlackBox
mqtt_config_loc=/etc/mosquitto

echo "Removing crontab settings..."
crontab -r

echo "Removing users..."
userdel usrmqttcontainer

echo "Removing groups..."
groupdel mqttcontainergroup

#Remove pahomqtt lib files
#rm $lib_loc*
rm $lib_loc/libpaho-mqtt3a.so
rm $lib_loc/libpaho-mqtt3a.so.1
rm $lib_loc/libpaho-mqtt3a.so.1.0
#
rm $lib_loc/libpaho-mqtt3as.so
rm $lib_loc/libpaho-mqtt3as.so.1
rm $lib_loc/libpaho-mqtt3as.so.1.0
#
rm $lib_loc/libpaho-mqtt3c.so
rm $lib_loc/libpaho-mqtt3c.so.1
rm $lib_loc/libpaho-mqtt3c.so.1.0
#
rm $lib_loc/libpaho-mqtt3cs.so
rm $lib_loc/libpaho-mqtt3cs.so.1
rm $lib_loc/libpaho-mqtt3cs.so.1.0


rm $bb_bin_loc

systemctl disable blackbox.service
rm -rf /etc/systemd/system/blackbox.service

rm -f -r $bb_config_loc

rm -f -r $mqtt_config_loc

#Rebuilds the statically linked library links
#Needed because we remove some libraries
ldconfig

#Ask to remove containers we created
read -p "Remove docker containers installed by LSOC installer? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing containers..."
    docker rm --force mqtt
    docker rm --force database_postgres
    docker rm --force lsoc_webinterface_django lsoc_webinterface_nginx lsoc_webinterface_postgres redis
fi

#Ask to remove volumes we created 
read -p "Remove volumes installed by LSOC installer? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing volumes..."
    docker volume rm postgres_volume static_volume media_volume
fi

#Ask to remove networks we created 
read -p "Remove networks installed by LSOC installer? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing networks..."
    docker network rm nginx_network postgres_network redis_network mosquitto_network
fi

#Ask to prune docker (remove unnecesary images, volumes, networks, containers) 
read -p "Prune docker (including volumes)? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker system prune --volumes -f
fi

#Ask to remove docker and docker-compose
read -p "Remove docker? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstalling docker"
    apt remove docker.io
fi
read -p "Remove docker-compose? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstalling docker-compose"
    apt remove docker-compose
fi

echo "Resetting firewall(ufw)..."
ufw reset

echo "Uninstall completed."

read -p "Press [Enter] to exit."

