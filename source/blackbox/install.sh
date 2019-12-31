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
black_box gen_settings

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

comp_psplit=$((black_box gen_neco_credentials) 2>&1 > /dev/null)
IFS=':' read -ra comp_arr <<< $comp_psplit
comp_username=${comp_arr[0]}
comp_password=${comp_arr[1]}

if [ -z "$comp_username" ] || [ -z "$comp_password" ]; then
    echo "could not generate NECO username/password pair. This needs to be done manually."
    comp_username="_"
    comp_password="_"
fi

# Here we prepare for configuring the NECO component backhaul credentials
read -p $'\e[1m\e[45mBlackBox Communicator Installer\e[0m: Specify the ip address of the component backhaul server [127.0.0.1]: ' comp_ip
comp_ip=${comp_ip:-'127.0.0.1'}

read -p $'\e[1m\e[45mBlackBox Communicator Installer\e[0m: Specify the port of the MQTT server [8883]: ' comp_port
comp_port=${comp_port:-'8883'}

read -p $'\e[1m\e[45mBlackBox Communicator Installer\e[0m: Path to the CA certificate file (THE PATH MUST END WITH A FILE EXTENSION!) [/etc/mosquitto/ca.crt]: ' comp_ca_path
comp_ca_path=${comp_ca_path:-'/etc/mosquitto/ca.crt'}

neutron_communicator comp_backhaul_credentials \
    -i "$comp_ip" \
    -p "$comp_port" \
    -u "$comp_username" \
    -w "$comp_password" \
    -c "$comp_ca_path"

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Enabling service..."
systemctl enable $service_source

if [[ "$*" == *--start_service* ]]; then
    echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Starting service..."
    systemctl start $service_source
fi

# Add the BlackBox component to NECO
neutron_communicator update_component add \
    --name "BlackBox" \
    --owner "root" \
    --owner_group "root" \
    --permissions "700" \
    --version_file_path "$config_dir_path/blackbox.version" \
    --service_name "$service_source" \
    --restart_command "sudo systemctl restart $service_source"

echo -e "\e[1m\e[45mBlackBox Installer\e[0m: Installation complete."
