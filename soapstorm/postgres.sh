#!/bin/bash

POSTGRES_CONTAINER_NAME=${POSTGRES_CONTAINER_NAME:-soapstorm-postgres}
POSTGRES_USER=${POSTGRES_USER:-rainwave}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-soapstorm-pass}


sudo docker kill $POSTGRES_CONTAINER_NAME
sudo docker rm $POSTGRES_CONTAINER_NAME
sudo docker run --name $POSTGRES_CONTAINER_NAME -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD -e POSTGRES_USER=$POSTGRES_USER -d postgres
sleep 4
POSTGRES_HOST=`sudo docker inspect $POSTGRES_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`
POSTGRES_PORT=5432
sudo docker run -it -e PGPASSWORD=$POSTGRES_PASSWORD --rm --link $POSTGRES_CONTAINER_NAME:postgres postgres psql -h postgres -U $POSTGRES_USER --command="CREATE EXTENSION IF NOT EXISTS pg_trgm;"


echo "Postgres Container Name: " $POSTGRES_CONTAINER_NAME
echo "Postgres Auth: " $POSTGRES_USER "/" $POSTGRES_PASSWORD
echo "Postgres Host: " $POSTGRES_HOST
echo "Postgres Port: " $POSTGRES_PORT
