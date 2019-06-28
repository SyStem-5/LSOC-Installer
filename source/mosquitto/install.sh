#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

# If no arguments are specified, exit
if [ -z "$1" ]; then
    echo "No configuration base directory specified. Exiting..."
    exit 1
fi

# If the mosquitto configuration directory hasn't been specified
# Set it to the default value
if [ -z "$2" ]; then
    echo -e "\e[1m\e[45mMosquitto Installer\e[0m: No mosquitto base directory specified, using default: '/etc/mosquitto'"
    mqtt_base_loc=/etc/mosquitto
else
    mqtt_base_loc=$2
fi

read -p $'\e[1m\e[45mMosquitto Installer\e[0m: Install Mosquitto? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

config_base_loc=$1

mosquitto_port=8883

usrmqttgroup="mqttcontainergroup"
usrmqtt="usrmqttcontainer"

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Creating mosquitto user..."

groupadd $usrmqttgroup -g $mosquitto_port
useradd $usrmqtt -u $mosquitto_port

usermod -a -G $usrmqttgroup $usrmqtt

pass=$(openssl rand -base64 32)
echo "$usrmqtt:$pass" | sudo chpasswd


if [ ! -d "$mqtt_base_loc" ]; then
    echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Creating mosquitto configuration directory..."
    mkdir $mqtt_base_loc
fi

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Setting permissions..."
#Make the directory and everything in it root:rwx usrmqttcontainer:r
chown -R root:$usrmqttgroup $mqtt_base_loc
chmod -R 740 $mqtt_base_loc

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying docker run command file..."
cp mosquitto_docker/docker_run.sh $config_base_loc/docker_run_mosquitto

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying mosquitto version file..."
cp mosquitto_docker/version $config_base_loc/mosquitto.version

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installing docker image..."

docker build -t mosquitto mosquitto_docker/

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Running docker image..."

#On first run; Run the Mosquitto docker image as "usrmqttcontainer" user pointing to the config file in /etc/mosquitto
mosquitto_conf_file_loc=$mqtt_base_loc/mosquitto.conf
docker run \
    --user $mosquitto_port:$mosquitto_port \
    --restart on-failure -d \
    -p 0.0.0.0:$mosquitto_port:$mosquitto_port \
    -v $mosquitto_conf_file_loc:/mosquitto/config/mosquitto.conf \
    --name mosquitto \
    --net=database \
    mosquitto

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh $config_base_loc/docker_run_mosquitto.sh") | crontab -

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installation Complete."
