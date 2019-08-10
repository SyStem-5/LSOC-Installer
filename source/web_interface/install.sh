#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Install the Web Interface? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

config_base_loc=/etc/LSOCWebInterface
deployed_dir_name=webinterface_docker

mkdir $config_base_loc

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installing docker-compose..."
apt install -y docker-compose

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Creating web_interface user..."

groupadd web_interface_group
useradd --system -s /bin/bash --groups web_interface_group,docker web_interface

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Copying docker run script..."
echo \
"#!/bin/bash

# Try to connect mosquitto container to our network
sudo docker network connect ${deployed_dir_name//_}_mosquitto_network mosquitto

# System config for Redis
sudo sysctl vm.overcommit_memory=1
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled

sudo -u web_interface docker-compose -f $config_base_loc/$deployed_dir_name/docker-compose.yml up -d --build" \
> $config_base_loc/docker_run_webinterface.sh && chmod 770 $config_base_loc/docker_run_webinterface.sh

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Deploying the webapp to the base directory..."
cp -r $deployed_dir_name $config_base_loc

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Generating the secret key for the web-app..."
echo $(openssl rand -base64 55) > $config_base_loc/$deployed_dir_name/secret_key.txt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Generating database credentials..."
echo "postgres" > $config_base_loc/$deployed_dir_name/sql_user.txt
echo $(openssl rand -base64 32) > $config_base_loc/$deployed_dir_name/sql_pass.txt

if [[ "$*" == *--self_signed* ]]; then
    neutron_communicator add_certificate \
        --name WebInterface \
        --algorithm rsa:2048 \
        --not_encrypted \
        --certificate_duration 365 \
        --subj /C=HR/ST=Croatia \
        --cert_file $config_base_loc/$deployed_dir_name/site.crt \
        --key_file $config_base_loc/$deployed_dir_name/site.key \
        --service_ips 'IP:127.0.0.1'
fi

if [ -d "/etc/mosquitto" ]; then
    echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Found Mosquitto installed, adding WebInterface as an auxiliary path for the CA certificate..."

    # Run neutron_communicator to add an aux path for the ca certificate
    neutron_communicator add_cert_aux_paths \
        --name Mosquitto \
        --type ca \
        --paths /dev/null $config_base_loc/$deployed_dir_name/mqtt_ca.crt
else
    echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: For the WIs moquitto connection to work, the MQTT CA certificate is going to have to be manually copied into the WIs root install folder."
fi

# If we don't create a file right now, docker-compose will create a folder and will refuse to use a file if we try to change it
touch $config_base_loc/$deployed_dir_name/mqtt_ca.crt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Setting permissions..."
chown -R web_interface:web_interface_group $config_base_loc
chmod -R 740 $config_base_loc

chmod 444 $config_base_loc/$deployed_dir_name/sql_user.txt $config_base_loc/$deployed_dir_name/sql_pass.txt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Building and running Docker image."
sudo -u web_interface docker-compose -f $config_base_loc/$deployed_dir_name/docker-compose.yml up -d --build

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Username. Press [ENTER] for [admin] ' -r username
username=${username:-admin}

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Email. Press [ENTER] to skip. ' -r email

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Waiting 60sec for WebInterface to be ready..."
sleep 60

# Generate the password for the superuser web interface account
pass=$(openssl rand -base64 10)

docker exec -i -t $(sudo docker ps -aqf "name=webinterface_django") /bin/ash -c \
"echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$username', '$email', '$pass')\" | python manage.py shell"

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: \e[4mIT IS NOT RECOMMENDED TO KEEP A DIGITAL COPY OF THIS PASSWORD!\e[0m \n Web Interface superuser password: '"[$pass]."$'\nPress [ENTER] to continue. ' -r

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: A restart may be needed for the docker run script to be ran (MQTT network to WI)."

# Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh $config_base_loc/docker_run_webinterface.sh") | crontab -

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installation Complete."
