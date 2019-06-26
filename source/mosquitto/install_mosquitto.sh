#!/bin/bash

read -p $'\e[1m\e[45mMosquitto Installer\e[0m: Install Mosquitto? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

mqtt_base_loc=/etc/mosquitto
bb_config_base_loc=/etc/BlackBox
mosquitto_port=8883

usrmqttgroup="mqttcontainergroup"
usrmqtt="usrmqttcontainer"

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Creating mosquitto user..."

groupadd $usrmqttgroup -g $mosquitto_port
useradd $usrmqtt -u $mosquitto_port

usermod -a -G $usrmqttgroup $usrmqtt

pass=$(openssl rand -base64 32)
echo "$usrmqtt:$pass" | sudo chpasswd

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Creating mosquitto configuration directory..."
mkdir $mqtt_base_loc

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying default settings..."
#Copy the default configuration file so we can make sure the broker is restricted to localhost and set the permissions
#Also, don't overwrite if a config file exists already
cp -r -n mosquitto/mosquitto_docker/default_mosquitto.conf $mqtt_base_loc/mosquitto.conf

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Setting permissions..."
#Make the directory and everything in it root:rwx usrmqttcontainer:r
chown -R root:$usrmqttgroup $mqtt_base_loc
chmod -R 740 $mqtt_base_loc

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying docker run command file..."
cp mosquitto/mosquitto_docker/docker_run.sh $bb_config_base_loc/docker_run_mosquitto

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying mosquitto version file..."
cp mosquitto/mosquitto_docker/version $bb_config_base_loc/mosquitto.version

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installing docker image..."

cd mosquitto/mosquitto_docker/
docker build -t mosquitto .

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Running docker image..."

#On first run; Run the Mosquitto docker image as "usrmqttcontainer" user pointing to the config file in /etc/mosquitto
mosquitto_conf_file_loc=/etc/mosquitto/mosquitto.conf
docker run \
    --user $mosquitto_port:$mosquitto_port \
    --restart on-failure -d \
    -p 0.0.0.0:$mosquitto_port:$mosquitto_port \
    -v $mosquitto_conf_file_loc:/mosquitto/config/mosquitto.conf \
    --name mosquitto \
    --net=database \
    mosquitto

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh /etc/BlackBox/docker_run_mosquitto.sh") | crontab -

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installation Complete."
