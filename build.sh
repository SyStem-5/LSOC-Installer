#!/bin/bash

echo "Building Release"
build_dir=build/LSOCInstaller
rm -rf $build_dir

mkdir -p $build_dir

# Base install/uninstall scripts
rsync --info=progress2 source/install.sh        $build_dir
rsync --info=progress2 source/uninstall.sh      $build_dir

# NeutronCommunicator
rsync -a source/neutron_communicator $build_dir
rsync --info=progress2 ../LSOC-NeutronCommunicator/target/release/neutron_communicator $build_dir/neutron_communicator/

# BlackBox
rsync -a source/blackbox $build_dir
rsync --info=progress2 ../LSOC-BlackBox/target/release/black_box $build_dir/blackbox/

# Firewall
rsync --info=progress2 source/ufw/setup.sh $build_dir/ufw/

# Mosquitto
rsync -a source/mosquitto                       $build_dir --exclude *.tar
rsync -a --info=progress2 ../Mosquitto-Auth-DockerImage/ $build_dir/mosquitto/mosquitto_docker \
    --exclude .vscode \
    --exclude .git \
    --exclude .gitignore \
    --exclude .gitmodules

# Postgress
rsync -a source/postgres                        $build_dir --exclude *.tar

## Web Interface ##

# Copy the install script from LSOC-Installer
rsync -a --info=progress2 source/web_interface  $build_dir \
    --exclude nginx.conf \
    --exclude docker-compose.yml

# Web Application - Copy the WebApp docker images
rsync -a --info=progress2 ../WebApp-Docker/ $build_dir/web_interface/webinterface_docker \
    --exclude .git \
    --exclude README.md

# Web Application - Copy our docker-compose file and nginx configuration
rsync --info=progress2 source/web_interface/nginx.conf $build_dir/web_interface/webinterface_docker/nginx/
rsync --info=progress2 source/web_interface/docker-compose.yml $build_dir/web_interface/webinterface_docker/

# Copy the actual django web application
rsync -a --info=progress2 ../LSOC-WebInterface/ $build_dir/web_interface/webinterface_docker/django/app \
    --exclude .vscode \
    --exclude .git \
    --exclude __pycache__ \
    --exclude README.md \
    --exclude run_dev_server.sh \
    --exclude set_dev_env_vars.sh \
    --exclude .gitignore

# Copy the version file to the base dir two levels lower
mv $build_dir/web_interface/webinterface_docker/django/app/webinterface.version $build_dir/web_interface/webinterface_docker
