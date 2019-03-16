# Pull official base image
FROM python:3.7-alpine

# Set environment varibles
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set work directory
WORKDIR /usr/src/djangoapp

# Install psycopg2
RUN apk update \
    && apk add --virtual build-deps gcc python3-dev musl-dev  \
    && apk add postgresql-dev
#   && apk add tree \

# Install dependencies
RUN pip install --upgrade pip \
    && pip install pipenv
#RUN pip install pipenv
COPY app/Pipfile /usr/src/djangoapp/Pipfile
COPY app/Pipfile.lock /usr/src/djangoapp/Pipfile.lock
RUN pipenv install --ignore-pipfile \
    && apk del build-deps
# --skip-lock --system --dev

# Copy entrypoint.sh
COPY ./entrypoint.sh /entrypoint.sh

# Copy project
COPY ./app /usr/src/djangoapp/

#RUN tree -a /usr/src/

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
