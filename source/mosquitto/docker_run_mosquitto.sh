#!/bin/bash

echo '0.1.0' > '/etc/BlackBox/mosquitto.version'

sudo docker container start mqtt
