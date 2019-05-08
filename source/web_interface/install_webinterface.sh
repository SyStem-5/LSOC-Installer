#!/bin/bash

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Install BlackBox Web Interface? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

bb_config_base_loc=/etc/BlackBox/

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installing docker-compose."

apt install -y docker-compose

#Copy the script for running WI docker container
cp web_interface/docker_run_webinterface.sh $bb_config_base_loc

#Copy the docker app to $bb_config_base_loc
cp -r web_interface/webinterface_docker $bb_config_base_loc

cd $bb_config_base_loc

chown root:root webinterface_docker
chmod 740 webinterface_docker

cd webinterface_docker/

secret_key=$(openssl rand -base64 55)
echo $secret_key >> secret_key.txt

echo "postgres" >> sql_user.txt
sql_pass=$(openssl rand -base64 32)
echo $sql_pass >> sql_pass.txt

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Loading Docker container."

docker-compose up -d --build

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Username. Press [ENTER] for [admin] ' -r username
username=${username:-admin}

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: Set Web Interface Email. Press [ENTER] to skip. ' -r email

pass=$(openssl rand -base64 32)

docker exec -i -t $(sudo docker ps -aqf "name=lsoc_webinterface_django") /bin/ash -c \
"echo \"from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$username', '$email', '$pass')\" | python manage.py shell"

read -p $'\e[1m\e[45mWeb Interface Installer\e[0m: \e[4mIT IS NOT RECOMMENDED TO KEEP A DIGITAL COPY OF THIS PASSWORD!\e[0m \n Web Interface superuser password: '"[$pass]."$'\nPress [ENTER] to continue. ' -r

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh /etc/BlackBox/docker_run_webinterface.sh") | crontab -

echo -e "\e[1m\e[45mWeb Interface Installer\e[0m: Installation Complete."
