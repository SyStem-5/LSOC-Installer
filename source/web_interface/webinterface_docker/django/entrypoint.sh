#!/bin/sh

echo "Waiting for postgres..."
while ! nc -z $SQL_HOST $SQL_PORT; do sleep 1; done
echo "PostgreSQL is up - continuing execution."

cd /usr/src/djangoapp

python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --no-input

exec "$@"
