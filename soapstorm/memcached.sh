#!/bin/bash

MEMCACHED_CONTAINER_NAME=${MEMCACHED_CONTAINER_NAME:-soapstorm-memcached}
MEMCACHED_MEMORY=${MEMCACHED_MEMORY:-512m}

sudo docker kill $MEMCACHED_CONTAINER_NAME
sudo docker rm $MEMCACHED_CONTAINER_NAME
sudo docker run --name $MEMCACHED_CONTAINER_NAME -d memcached -m $MEMCACHED_MEMORY
sleep 1
MEMCACHED_HOST=`sudo docker inspect $MEMCACHED_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`
MEMCACHED_PORT=11211


echo "Memcached Container Name: " $MEMCACHED_CONTAINER_NAME
echo "Memcached Memory: " $MEMCACHED_MEMORY
echo "Memcached Host: " $MEMCACHED_HOST
echo "Memcached Port: " $MEMCACHED_PORT
