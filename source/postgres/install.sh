#!/bin/bash

# Set the workdir to the directory the script is in
cd "$(dirname "$0")"

read -p $'\e[1m\e[45mPostgreSQL Installer\e[0m: Install PostgreSQL? [Y/n] ' -r REPLY
REPLY=${REPLY:-y}
echo    #Move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

# If no arguments are specified, exit
if [ -z "$1" ]; then
    echo "No configuration base directory specified. Exiting..."
    exit 1
fi

config_base_location=$1
creds_file_loc=$config_base_location/postgresql_bb.creds
pg_major_version=11
postgres_package=postgres:$pg_major_version-alpine

if [ ! -d "$config_base_location" ]; then
    echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Creating base configuration directory. Path: $config_base_location."
    mkdir $config_base_location
fi

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Generating and saving a version file. v$pg_major_version.0.0"
echo $pg_major_version.0.0 > $config_base_location/postgresql.version

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Generating and saving postgres credentials..."
creds=$(openssl rand -base64 32)
echo $creds > $creds_file_loc

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Copying docker run script to the base configuration directory..."
echo \
'#!/bin/bash
sudo docker container start database_postgres' \
> $config_base_location/docker_run_postgresql.sh

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Creating the docker database network..."
docker network create database

#On first run; Run the PostgreSQL docker image with the password from file in /etc/BlackBox and as "postgresql" user pointing to the database file in /etc/postgres
password=$(<$creds_file_loc);
docker run --restart on-failure -d \
    -p 127.0.0.1:5432:5432 \
    --net=database \
    --name database_postgres \
    -v postgres:/var/lib/postgresql/data \
    -e POSTGRES_PASSWORD=$password $postgres_package

#Make crontab start the script(as root) on reboot so it starts even when no one is logged in
(crontab -l 2>/dev/null; echo "@reboot /bin/sh $config_base_location/docker_run_postgresql.sh") | crontab -

echo -e "\e[1m\e[45mPostgreSQL Installer\e[0m: Installation Complete."
