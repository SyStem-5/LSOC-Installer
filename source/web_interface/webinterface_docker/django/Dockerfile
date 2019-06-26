FROM python:3.7-alpine

ENV PYTHONDONTWRITEBYTECODE 1 \
    PYTHONUNBUFFERED 1

# Easier pipenv execution
WORKDIR /usr/src/djangoapp

COPY ./app /usr/src/djangoapp/
COPY ./entrypoint.sh /entrypoint.sh

RUN apk update \
    && apk add --no-cache --virtual build-deps gcc python3-dev musl-dev  \
    && apk add --no-cache postgresql-dev \
    && pip install --upgrade pip \
    && pip install pipenv \
    && pipenv install --ignore-pipfile --system \
    && apk del build-deps \
    && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
