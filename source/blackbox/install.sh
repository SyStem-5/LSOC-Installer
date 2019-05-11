#!/bin/bash

echo -e "\e[1m\e[44mLSOC Installer\e[0m: Installing BlackBox"

### VARIABLES ###
bin_loc=/bin/black_box
bin_source=blackbox/black_box
#
service_loc=/etc/systemd/system/blackbox.service
service_source=blackbox/blackbox.service
#
bb_config_dir=/etc/BlackBox/
bb_settings_file_loc=/etc/BlackBox/settings.json
#
mosquitto_config_dir=/etc/mosquitto/
mosquitto_config_file=/etc/mosquitto/mosquitto.conf

# BB create the config folder and set permissions
mkdir $bb_config_dir
chown root:root $bb_config_dir
chmod 700 $bb_config_dir

# Copy the binary and set permissions
cp $bin_source $bin_loc
chown root:root $bin_loc
chmod 700 $bin_loc

# BB Config file setup
read -p $'\e[1m\e[44mLSOC Installer\e[0m: Default BlackBox settings file is going to be generated, please edit the file responsibly. To continue press [ENTER] ' -r
black_box gen_settings
nano $bb_settings_file_loc

# Mosquitto config setup
read -p $'\e[1m\e[44mLSOC Installer\e[0m: Generate Mosquitto configuration file? [Y/n] ' -r
REPLY=${REPLY:-y}
if [[ $REPLY =~ ^[Yy]$ ]]; then
    #Just to be sure, we create a directory
    #This assumes the configuration is saved to /etc/mosquitto/
    mkdir $mosquitto_config_dir
    black_box gen_mosquitto_conf
    nano $mosquitto_config_file
fi

# Service setup
cp $service_source $service_loc
chmod 750 $service_loc
systemctl enable blackbox.service
echo -e "\e[1m\e[44mLSOC Installer\e[0m: BlackBox installation complete."
