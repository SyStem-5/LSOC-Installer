#!/bin/bash

version_file=/etc/BlackBox/postgresql.version

echo '0.1.0' > $version_file

# Remove \n from the end
truncate -s -1 $version_file

sudo docker container start database_postgres
