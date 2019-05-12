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
rsync --info=progress2 source/ufw_setup/firewall_setup.sh $build_dir/ufw_setup/

# Mosquitto
rsync -a source/mosquitto                       $build_dir --exclude *.tar
rsync -a --info=progress2 ../Mosquitto-Auth-DockerImage/ $build_dir/mosquitto/mosquitto_docker \
    --exclude .vscode \
    --exclude .git \
    --exclude .gitignore \
    --exclude .gitmodules
rsync -a --info=progress2 ../Mosquitto-Auth-Plugin/ $build_dir/mosquitto/mosquitto_docker/Mosquitto-Auth-Plugin \
    --exclude .vscode \
    --exclude .git \
    --exclude .gitignore \
    --exclude .gitmodules

# Postgress
rsync -a source/postgres                        $build_dir --exclude *.tar

# Web Interface
rsync -a --info=progress2 source/web_interface  $build_dir
rsync -a --info=progress2 ../LSOC-WebInterface/ $build_dir/web_interface/webinterface_docker/django/app \
    --exclude .vscode \
    --exclude .git \
    --exclude __pycache__ \
    --exclude README.md \
    --exclude run_dev_server.sh \
    --exclude set_dev_env_vars.sh \
    --exclude .gitignore
