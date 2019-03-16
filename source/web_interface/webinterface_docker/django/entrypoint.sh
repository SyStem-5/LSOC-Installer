#!/bin/sh

if [ "$DATABASE" = "postgres" ]
then
    echo "Waiting for postgres..."

    while ! nc -z $SQL_HOST $SQL_PORT; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

#tree -a /usr/src/djangoapp/

cd /usr/src/djangoapp
#python manage.py flush --no-input

#python manage.py migrate
#python manage.py collectstatic --no-input

pipenv run python manage.py makemigrations
pipenv run python manage.py migrate
pipenv run python manage.py collectstatic --no-input

exec "$@"
