#!/bin/bash

version_file=/etc/BlackBox/webinterface.version

echo '0.1.0' > $version_file

# Remove \n from the end
truncate -s -1 $version_file

wi_base_loc=/etc/BlackBox/webinterface_docker/
cd $wi_base_loc

#Wait a bit, if a mosquitto container is on this system we're going to try to connect it to our network
sleep 5

sudo docker network connect webinterfacedocker_mosquitto_network mqtt

#System config for Redis
sudo sysctl vm.overcommit_memory=1
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled

sudo docker-compose up -d --build
