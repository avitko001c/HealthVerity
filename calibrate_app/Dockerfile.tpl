# pull official base image
FROM python:3.8.5-slim-buster
ENV RDS_DB_NAME='ChangeMeRDS'
ENV RDS_USERNAME='ChangeMeUsername'
ENV RDS_PASSWORD='ChangeMePassword'
ENV RDS_HOSTNAME='ChangeMeHostname'
ENV RDS_PORT='ChangeMePort'

# set work directory
WORKDIR /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# install psycopg2 dependencies
RUN apt-get update \
  && apt-get -y install gcc postgresql \
  && apt-get clean

# install dependencies
RUN pip install --upgrade pip
COPY ./requirements.txt .
RUN pip install -r requirements.txt

# expose port
EXPOSE 8000

# copy project
COPY . .

# collect static files
RUN python manage.py collectstatic --no-input
# migrate the app to the database and run the server
RUN python manage.py migrate
RUN python manage runserver &
