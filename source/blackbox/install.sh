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
    echo -e "\e[1m\e[45mBlackBox Installer\e[0m: No mosquitto configuration directory specified, using default: '/etc/mosquitto'"
    mosquitto_config_dir=/etc/mosquitto
else
    mosquitto_config_dir=$2
fi

read -p $'\e[1m\e[45mBlackBox Installer\e[0m: Install BlackBox? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Installing BlackBox"

config_dir_path=$1

binary_name=black_box
binary_destination=/bin/$binary_name

bb_gen_settings_cmd=gen_settings
bb_gen_mqtt_settings_cmd=gen_mosquitto_conf

service_source=blackbox.service
service_destination=/etc/systemd/system/$service_source

bb_settings_file_loc=$config_dir_path/settings.json
mosquitto_config_file=$mosquitto_config_dir/mosquitto.conf

# BB create the config folder and set permissions
echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Creating the configuration directory. Path: $config_dir_path."
mkdir $config_dir_path

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Setting permissions..."
chown -R root:root $config_dir_path
chmod -R 700 $config_dir_path

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Deploying the binary..."
cp $binary_name $binary_destination

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Setting the permissions..."
chown root:root $binary_destination
chmod 700 $binary_destination

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Generating default settings..."
black_box $bb_gen_settings_cmd

read -p $'\e[1m\e[45mBlackBox Installer\e[0m: Edit the configuration file? [y/N] ' -r
REPLY=${REPLY:-n}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nano $bb_settings_file_loc
fi

# Mosquitto config setup
read -p $'\e[1m\e[45mBlackBox Installer\e[0m: Generate Mosquitto configuration file? [Y/n] ' -r
REPLY=${REPLY:-y}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    #Just to be sure, we create a directory
    #This assumes the configuration is saved to /etc/mosquitto/
    mkdir $mosquitto_config_dir
    black_box $bb_gen_mqtt_settings_cmd

    read -p $'\e[1m\e[45mBlackBox Installer\e[0m: Edit the configuration file? [y/N] ' -r
    REPLY=${REPLY:-n}
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        nano $mosquitto_config_file
    fi
fi

# Service setup
echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Copying the service file..."
cp $service_source $service_destination

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Setting permissions..."
chmod 750 $service_destination

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Enabling service..."
systemctl enable $service_source

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Installation complete."
