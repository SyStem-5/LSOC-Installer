#!/bin/bash

echo '{"version":"0.1.0"}' > '/etc/BlackBox/mosquitto_version.json'

sudo docker container start mqtt