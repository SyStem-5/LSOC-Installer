#!/bin/bash

echo '0.1.0' > '/etc/BlackBox/postgresql.version'

sudo docker container start database_postgres
