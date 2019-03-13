#!/bin/bash

echo '{"version":"0.1.0"}' > '/etc/BlackBox/postgresql_version.json'

sudo docker container start database_postgres