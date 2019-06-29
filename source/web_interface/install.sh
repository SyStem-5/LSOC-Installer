#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

# If no arguments are specified, exit
if [ -z "$1" ]; then
    echo "No configuration base directory specified. Exiting..."
    exit 1
fi

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Install the Web Interface? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

config_base_loc=$1
deployed_dir_name=webinterface_docker

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installing docker-compose..."
apt install -y docker-compose

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Copying docker run command file..."
cp docker_run_webinterface.sh $config_base_loc

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Deploying the webapp to the base directory..."
cp -r $deployed_dir_name $config_base_loc

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Setting permissions..."
chown -R root:root $config_base_loc/$deployed_dir_name
chmod -R 740 $config_base_loc/$deployed_dir_name

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Generating the secret key for the web-app..."
echo $(openssl rand -base64 55) > $config_base_loc/$deployed_dir_name/secret_key.txt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Generating database credentials..."
echo "postgres" > $config_base_loc/$deployed_dir_name/sql_user.txt
echo $(openssl rand -base64 32) > $config_base_loc/$deployed_dir_name/sql_pass.txt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Generating self-signed SSL certificate..."
openssl req \
       -newkey rsa:2048 -nodes -keyout $config_base_loc/$deployed_dir_name/site.key \
       -x509 -days 750 -out $config_base_loc/$deployed_dir_name/site.crt \
       -subj "/C=HR/ST=Croatia"

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Building and running Docker image."
docker-compose -f $config_base_loc/$deployed_dir_name/docker-compose.yml up -d --build

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Username. Press [ENTER] for [admin] ' -r username
username=${username:-admin}

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Email. Press [ENTER] to skip. ' -r email

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Waiting 60sec for WebInterface to go online..."
sleep 60

# Generate the password for the superuser web interface account
pass=$(openssl rand -base64 32)

docker exec -i -t $(sudo docker ps -aqf "name=lsoc_webinterface_django") /bin/ash -c \
"echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$username', '$email', '$pass')\" | python manage.py shell"

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: \e[4mIT IS NOT RECOMMENDED TO KEEP A DIGITAL COPY OF THIS PASSWORD!\e[0m \n Web Interface superuser password: '"[$pass]."$'\nPress [ENTER] to continue. ' -r

# Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh $config_base_loc/docker_run_webinterface.sh") | crontab -

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installation Complete."
