#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Starting Neutron Communicator Installation"

neco_gen_settings_cmd=gen_settings
binary_name=neutron_communicator
binary_destination=/bin/$binary_name
service_file_destination=/etc/systemd/system
service_file_name=neutroncommunicator.service
config_dir=/etc/NeutronCommunicator

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Copying the binary..."
cp $binary_name /bin/

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Setting permissions..."
chown root:root $binary_destination
chmod 700 $binary_destination

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Creating the configuration directory..."
mkdir $config_dir

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Setting permissions..."
chown -R root:root $config_dir
chmod -R 600 $config_dir

read -p $'\e[1m\e[45mNeutron Communicator Installer\e[0m: Default NECO settings file is going to be generated, please edit the file responsibly. To continue press [ENTER] ' -r
$binary_name $neco_gen_settings_cmd
nano $config_dir/settings.json

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Copying the service file..."
cp $service_file_name $service_file_destination

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Setting permissions..."
chmod 750 $service_file_destination/$service_file_name

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: Enabling service..."
systemctl enable $service_file_name

# Here we prepare for configuring the Neutron credentials
until [ ! -z "$user" ]
do
    read -p $'\e[1m\e[45mNeutron Communicator Installer\e[0m: Specify the account username under which this NECO is registered: ' user
done

until [ ! -z "$mqtt_username" ]
do
    read -p $'\e[1m\e[45mNeutron Communicator Installer\e[0m: Specify the MQTT username of the registered updater: ' mqtt_username
done

until [ ! -z "$mqtt_password" ]
do
    read -p $'\e[1m\e[45mNeutron Communicator Installer\e[0m: Specify the MQTT password of the registered updater: ' mqtt_password
done

neutron_communicator neutron_credentials \
    -a "$user" \
    -u "$mqtt_username" \
    -p "$mqtt_password"

echo -e "\e[1m\e[45mNeutron Communicator Installer\e[0m: NECO installation complete."
