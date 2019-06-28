#!/bin/bash

read -p $'\e[1m\e[44mLSOC Installer\e[0m: Install PostgreSQL? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

# We can create it here, it doesn't matter if it fails or doesn't, permissions will be set anyway
bb_config_base_loc=/etc/BlackBox/
mkdir $bb_config_base_loc

postgres_package=postgres:11-alpine
postgres_container_local=postgres/postgres.tar
#Generate the password for postgresql(docker image) and save it to /etc/BlackBox name: postgresql_bb.creds
creds=$(openssl rand -base64 32)
echo $creds >> $bb_config_base_loc/postgresql_bb.creds

#Copy the script for running postgresql docker container
cp postgres/docker_run_postgresql.sh $bb_config_base_loc

#If the local container exists, we ask to install local or download the container from the internet
if [ -f $postgres_container_local ]; then
    read -p $'\e[1m\e[45mPostgreSQL Installer\e[0m: Download the PostgreSQL docker container? [Y/n] ' -r
    REPLY=${REPLY:-y}
    echo    #Move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        docker pull $postgres_package
    else
        #Load the docker container
        docker load < $postgres_container_local
    fi
else
    echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Downloading PostgreSQL container."
    docker pull $postgres_package
fi

#Create the network so other containers can connect
docker network create database

#On first run; Run the PostgreSQL docker image with the password from file in /etc/BlackBox and as "postgresql" user pointing to the database file in /etc/postgres
creds_file_loc=/etc/BlackBox/postgresql_bb.creds
password=$(<$creds_file_loc);
docker run --restart on-failure -d \
    -p 127.0.0.1:5432:5432 \
    --net=database \
    --name database_postgres \
    -v postgres:/var/lib/postgresql/data \
    -e POSTGRES_PASSWORD=$password $postgres_package

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh /etc/BlackBox/docker_run_postgresql.sh") | crontab -

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Installation Complete."
