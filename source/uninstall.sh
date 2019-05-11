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

bb_bin_loc=/bin/black_box
bb_config_loc=/etc/BlackBox
mqtt_config_loc=/etc/mosquitto

read -p "Reset crontab? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing crontab settings..."
    crontab -r
fi

echo "Removing users..."
userdel usrmqttcontainer

echo "Removing groups..."
groupdel mqttcontainergroup

rm $bb_bin_loc

systemctl disable blackbox.service
rm -rf /etc/systemd/system/blackbox.service

rm -f -r $bb_config_loc

rm -f -r $mqtt_config_loc


#Ask to remove containers we created
read -p "Remove docker containers installed by LSOC installer? [y/N] " -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing containers..."
    docker rm --force mqtt
    docker rm --force database_postgres
    docker rm --force lsoc_webinterface_django lsoc_webinterface_nginx lsoc_webinterface_postgres lsoc_webinterface_redis
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
