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
if [ -z "$2" ] || [[ "$2" == *--* ]]; then
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

# Create the directory only if it doesn't exist
if [ ! -d "$mqtt_base_loc" ]; then
    echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Creating mosquitto configuration directory..."
    mkdir $mqtt_base_loc
fi

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Setting permissions..."
#Make the directory and everything in it root:rwx usrmqttcontainer:r
chown -R root:$usrmqttgroup $mqtt_base_loc
chmod -R 740 $mqtt_base_loc

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying docker run command file and setting permissions..."
cp mosquitto_docker/docker_run.sh $config_base_loc/docker_run_mosquitto.sh
chmod 770 $config_base_loc/docker_run_mosquitto.sh

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Copying mosquitto version file..."
cp mosquitto_docker/version $config_base_loc/mosquitto.version

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installing docker image..."

docker build -t mosquitto mosquitto_docker/

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Running docker image..."

#On first run; Run the Mosquitto docker image as "usrmqttcontainer" user pointing to the config file in /etc/mosquitto
mosquitto_conf_file_loc=$mqtt_base_loc/mosquitto.conf

if [[ "$*" == *--neus* ]]; then
    network_name=webinterfacedocker_mosquitto_network
else
    network_name=database
fi

# Create an array for arguments
declare -a docker_run_args

docker_run_args+=(--user $mosquitto_port:$mosquitto_port)
docker_run_args+=(--restart on-failure -d)
docker_run_args+=(-p 0.0.0.0:$mosquitto_port:$mosquitto_port)

# If the configuration file doesn't exist, we dont suppy a volume argument pointing to something that doesn't exist
if [ -f "$mosquitto_conf_file_loc" ]; then
    docker_run_args+=(-v $mosquitto_conf_file_loc:/mosquitto/config/mosquitto.conf)
else
    echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Could not find external configuration. Using default..."
fi

docker_run_args+=(--name mosquitto)

# If the network name exists, add it, else, notify the user that that network doesn't exist
if [ ! -z $(sudo docker network ls -qf "name=$network_name") ]; then
    docker_run_args+=(--net=$network_name)
else
    echo -e "\e[1m\e[45mMosquitto Installer\e[0m: [\e[91mError\e[0m] Could not find network '$network_name'. Skipping --net argument..."
fi

docker_run_args+=(mosquitto)

# Execute the command with the arguments from the array
docker run "${docker_run_args[@]}"

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh $config_base_loc/docker_run_mosquitto.sh") | crontab -

echo -e "\e[1m\e[45mMosquitto Installer\e[0m: Installation Complete."
