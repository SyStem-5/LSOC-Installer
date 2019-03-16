#!/bin/bash

echo "Building Release"
release_dir=build/LSOCInstaller
rm -rf $release_dir

mkdir -p $release_dir

rsync --info=progress2 ../LSOC-BlackBox/target/release/black_box $release_dir/blackbox/

rsync --info=progress2 source/blackbox/blackbox.service   $release_dir/blackbox/
rsync --info=progress2 source/install.sh        $release_dir
rsync --info=progress2 source/uninstall.sh      $release_dir
rsync --info=progress2 source/ufw_setup/firewall_setup.sh $release_dir/ufw_setup/


rsync -a source/mosquitto                       $release_dir --exclude *.tar
git clone https://github.com/SyStem-5/Mosquitto-Auth-DockerImage.git $release_dir/mosquitto/mosquitto_docker

git clone https://github.com/SyStem-5/Mosquitto-Auth-Plugin.git $release_dir/mosquitto/mosquitto_docker/mosquitto-auth-plugin

rsync -a source/postgres                        $release_dir --exclude *.tar


rsync -a --info=progress2 source/lib            $release_dir

rsync -a --info=progress2 source/web_interface  $release_dir

rsync -a --info=progress2 ../LSOC-WebInterface/ $release_dir/web_interface/webinterface_docker/django/app \
    --exclude .vscode \
    --exclude .git \
    --exclude __pycache__ \
    --exclude README.md \
    --exclude run_dev_server.sh \
    --exclude set_dev_env_vars.sh \
    --exclude .gitignore