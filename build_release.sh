#!/bin/bash

release_dir_base=build/release

if [ "$1" == "--download" ]; then
    echo "Building Release -- Download Only"
    release_dir=$release_dir_base/LSOCInstaller-DownloadOnly
    rm -rf $release_dir
else
    echo "Building Release"
    release_dir=$release_dir_base/LSOCInstaller
    rm -rf $release_dir
fi

mkdir -p $release_dir

rsync --info=progress2 ../black_box/target/release/black_box $release_dir/blackbox/

rsync --info=progress2 source/blackbox/blackbox.service   $release_dir/blackbox/
rsync --info=progress2 source/install.sh        $release_dir
rsync --info=progress2 source/uninstall.sh      $release_dir
rsync --info=progress2 source/ufw_setup/firewall_setup.sh $release_dir/ufw_setup/


if [ "$1" == "--download" ]; then
    rsync -a source/mosquitto                       $release_dir --exclude *.tar
    git clone https://github.com/SyStem-5/Mosquitto-Auth-DockerImage.git $release_dir/mosquitto
    mv $release_dir/mosquitto/Mosquitto-Auth-DockerImage $release_dir/mosquitto/mosquitto_docker

    rsync -a source/postgres                        $release_dir --exclude *.tar
else
    rsync --info=progress2 source/docker.deb        $release_dir/packages/
    rsync -a source/mosquitto                       $release_dir
    rsync -a source/postgres                        $release_dir
fi

rsync -a --info=progress2 source/lib            $release_dir

rsync -a --info=progress2 source/web_interface  $release_dir
rsync -a --info=progress2 ../lsoc_web_interface/project01/ $release_dir/web_interface/webinterface_docker/django/app \
    --exclude .vscode \
    --exclude __pycache__