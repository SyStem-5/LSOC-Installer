#!/bin/bash

echo "Building Release"
build_dir=build/LSOCInstaller
rm -rf $build_dir

mkdir -p $build_dir

rsync --info=progress2 ../LSOC-BlackBox/target/release/black_box $build_dir/blackbox/

rsync --info=progress2 source/blackbox/blackbox.service   $build_dir/blackbox/
rsync --info=progress2 source/install.sh        $build_dir
rsync --info=progress2 source/uninstall.sh      $build_dir
rsync --info=progress2 source/ufw_setup/firewall_setup.sh $build_dir/ufw_setup/


rsync -a source/mosquitto                       $build_dir --exclude *.tar
git clone https://github.com/SyStem-5/Mosquitto-Auth-DockerImage.git $build_dir/mosquitto/mosquitto_docker

git clone https://github.com/SyStem-5/Mosquitto-Auth-Plugin.git $build_dir/mosquitto/mosquitto_docker/mosquitto-auth-plugin

rsync -a source/postgres                        $build_dir --exclude *.tar


rsync -a --info=progress2 source/lib            $build_dir

rsync -a --info=progress2 source/web_interface  $build_dir

rsync -a --info=progress2 ../LSOC-WebInterface/ $build_dir/web_interface/webinterface_docker/django/app \
    --exclude .vscode \
    --exclude .git \
    --exclude __pycache__ \
    --exclude README.md \
    --exclude run_dev_server.sh \
    --exclude set_dev_env_vars.sh \
    --exclude .gitignore