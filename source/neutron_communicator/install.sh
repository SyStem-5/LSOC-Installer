echo -e "\e[1m\e[44mLSOC Installer\e[0m: Installing Neutron Communicator"

bin_name=neutron_communicator
bin_loc_source=neutron_communicator/$bin_name
bin_loc_dest=/bin/$bin_name
config_loc=/etc/NeutronCommunicator

# Binary copying and permissions
cp $bin_loc_source /bin/
chown root:root $bin_loc_dest
chmod 700 $bin_loc_dest

# Configuration dir permissions
mkdir $config_loc
chown root:root $config_loc
chmod 600 $config_loc

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Default NECO settings file is going to be generated, please edit the file responsibly. To continue press [ENTER] ' -r
$bin_name gen_settings
nano $config_loc/settings.json

# Service setup
cp neutron_communicator/neutroncommunicator.service /etc/systemd/system/
chmod 750 /etc/systemd/system/neutroncommunicator.service
systemctl enable neutroncommunicator.service

echo -e "\e[1m\e[44mLSOC Installer\e[0m: NECO installation complete."
