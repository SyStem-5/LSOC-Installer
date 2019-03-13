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
COPY ./Pipfile /usr/src/djangoapp/Pipfile
RUN pipenv install --skip-lock --system \
    && apk del build-deps
# --dev

# Copy entrypoint.sh
COPY ./entrypoint.sh /entrypoint.sh

# Copy project
COPY ./app /usr/src/djangoapp/

#RUN tree -a /usr/src/

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
