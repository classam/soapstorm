#!/bin/bash


SOAPSTORM_NAME=${SOAPSTORM_NAME:-Marquee}

HOST_MUSIC_DIRECTORY=${HOST_MUSIC_DIRECTORY:-`pwd`/../music}
MOUNT_MUSIC_DIRECTORY=${MOUNT_MUSIC_DIRECTORY:-/tmp/music}
OFFLINE_FILE=${OFFLINE_FILE:-$MOUNT_MUSIC_DIRECTORY/jamendo/Colaars_-_To_The_Roofs.mp3}

SOAPSTORM_DOMAIN=${SOAPSTORM_DOMAIN:-radio.marquee.click}

LIQUIDSOAP_CONTAINER_NAME=${LIQUIDSOAP_CONTAINER_NAME:-soapstorm-liquidsoap}
LIQUIDSOAP_PORT=9051
LIQUIDSOAP_PASSWORD=${LIQUIDSOAP_PASSWORD:-potato}

sudo docker kill $LIQUIDSOAP_CONTAINER_NAME
sudo docker rm $LIQUIDSOAP_CONTAINER_NAME

cat >./liquidsoap.liq <<END
#!/usr/bin/liquidsoap

# This is a sample LiquidSoap configuration file.
# It's what Rainwave uses in production, with some minor modifications.

# Used if your Rainwave instance crashes.  Will loop this MP3 until you restart RW.
rw_offline_file = "$OFFLINE_FILE"
# Rainwave Station ID.
rw_sid = "1"
rw_dest_mount = "radio"
rw_dest_desc = "$SOAPSTORM_NAME"
rw_dest_url = "http://$SOAPSTORM_DOMAIN"
# Allows users to DJ over music. (see Liq documentation)
rw_harbor_port = $LIQUIDSOAP_PORT

set("log.level", 4)

set("harbor.timeout", 4.)

set("server.socket", true)
set("server.socket.path", "/var/run/liquidsoap/<script>.sock")
set("server.socket.permissions", 432) # translates to 660 permissions but needs to be in octal format
set("server.timeout", -1.)
rw_harbor_pw = interactive.string("harbor_pw", "$LIQUIDSOAP_PASSWORD")

END

sudo docker run -p $LIQUIDSOAP_PORT:$LIQUIDSOAP_PORT --name $LIQUIDSOAP_CONTAINER_NAME -v `pwd`/liquidsoap.liq:/config/config.liq -v $HOST_MUSIC_DIRECTORY:$MOUNT_MUSIC_DIRECTORY -d moul/icecast
sleep 1
LIQUIDSOAP_HOST=`sudo docker inspect $LIQUIDSOAP_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`

echo "Liquidsoap Container Name: " $LIQUIDSOAP_CONTAINER_NAME
echo "Liquidsoap Host: " $LIQUIDSOAP_HOST
echo "Liquidsoap Port: " $LIQUIDSOAP_PORT
