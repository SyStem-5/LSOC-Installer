#!/bin/bash

wi_base_loc=/etc/BlackBox/webinterface_docker/
cd $wi_base_loc

sudo docker network connect webinterfacedocker_mosquitto_network mosquitto

#System config for Redis
sudo sysctl vm.overcommit_memory=1
sudo echo never > /sys/kernel/mm/transparent_hugepage/enabled

sudo docker-compose up -d --build
