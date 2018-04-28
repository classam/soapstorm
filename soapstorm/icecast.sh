#!/bin/bash

SOAPSTORM_NAME=${SOAPSTORM_NAME:-Marquee Radio}
SOAPSTORM_EMAIL=${SOAPSTORM_EMAIL:-marquis@marquee.click}
SOAPSTORM_DOMAIN=${SOAPSTORM_DOMAIN:-radio.marquee.click}
SOAPSTORM_STREAM=${SOAPSTORM_STREAM:-Marquee}

SOAPSTORM_USER=${SOAPSTORM_USER:-turbofunkradio}
SOAPSTORM_PASS=${SOAPSTORM_PASS:-asdasdasdasdasd}

ICECAST_CONTAINER_NAME=${ICECAST_CONTAINER_NAME:-soapstorm-icecast}
ICECAST_USER=${ICECAST_USER:-soapybutt}
ICECAST_SOURCE_PASSWORD=${ICECAST_PASSWORD:-asdasdasdasd}
ICECAST_RELAY_PASSWORD=${ICECAST_PASSWORD:-popopopopopop}
ICECAST_ADMIN=${ICECAST_USER:-buttsoap}
ICECAST_ADMIN_PASSWORD=${ICECAST_PASSWORD:-gorpgorpgorpgorp}
ICECAST_PORT=8000

LIQUIDSOAP_CONTAINER_NAME=${LIQUIDSOAP_CONTAINER_NAME:-soapstorm-liquidsoap}
LIQUIDSOAP_PORT=9051
LIQUIDSOAP_PASSWORD=${LIQUIDSOAP_PASSWORD:-horphorphorphorp}

HOST_MUSIC_DIRECTORY=${HOST_MUSIC_DIRECTORY:-/data/dropbox/Dropbox/Music}
MOUNT_MUSIC_DIRECTORY=${MOUNT_MUSIC_DIRECTORY:-/tmp/music}
OFFLINE_FILE=${OFFLINE_FILE:-$MOUNT_MUSIC_DIRECTORY/Bounce Traxx/Broken Bells - 02 - After the Disco.mp3}

GROOVE_MOUNT_POINT=${MOUNT_POINT:-groove.ogg}
CHILL_MOUNT_POINT=${MOUNT_POINT:-chill.ogg}

sudo docker kill $ICECAST_CONTAINER_NAME
sudo docker rm $ICECAST_CONTAINER_NAME

cat >./icecast.xml <<END
<icecast>
    <location>$SOAPSTORM_NAME</location>
    <admin>$SOAPSTORM_EMAIL</admin>

    <limits>
        <clients>100</clients>
        <sources>30</sources>
        <threadpool>5</threadpool>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>$ICECAST_SOURCE_PASSWORD</source-password>
        <relay-password>$ICECAST_RELAY_PASSWORD</relay-password>

        <admin-user>$ICECAST_ADMIN</admin-user>
        <admin-password>$ICECAST_ADMIN_PASSWORD</admin-password>
    </authentication>

    <hostname>$SOAPSTORM_DOMAIN</hostname>
    <listen-socket>
        <port>$ICECAST_PORT</port>
    </listen-socket>

    <fileserve>1</fileserve>

    <paths>
        <basedir>/usr/share/icecast2</basedir>
        <logdir>/var/log/icecast2</logdir>
        <webroot>/usr/share/icecast2/web</webroot>
        <adminroot>/usr/share/icecast2/admin</adminroot>
        <alias source="/" dest="/index.html"/>
    </paths>

    <logging>
        <accesslog>access.log</accesslog>
        <errorlog>error.log</errorlog>
        <loglevel>3</loglevel> <!-- 4 Debug, 3 Info, 2 Warn, 1 Error -->
        <logsize>10000</logsize> <!-- Max size of a logfile -->
    </logging>

    <security>
        <chroot>0</chroot>
        <!--
        <changeowner>
            <user>nobody</user>
            <group>nogroup</group>
        </changeowner>
        -->
    </security>

    <mount>
        <mount-name>/$GROOVE_MOUNT_POINT</mount-name>
        <public>1</public>
        <stream-name>Marquee Groove</stream-name>
        <stream-description>Running in the 90s</stream-description>
        <stream-url>http://$DOMAIN</stream-url>
    </mount>

    <mount>
        <mount-name>/$CHILL_MOUNT_POINT</mount-name>
        <public>1</public>
        <stream-name>Marquee Chill</stream-name>
        <stream-description>Instrumental AF</stream-description>
        <stream-url>http://$DOMAIN</stream-url>
    </mount>
</icecast>
END

sudo docker run \
    -p $ICECAST_PORT:$ICECAST_PORT \
    --name $ICECAST_CONTAINER_NAME \
    -v `pwd`/icecast.xml:/etc/icecast2/icecast.xml \
    -d moul/icecast

sleep 1
ICECAST_HOST=`sudo docker inspect $ICECAST_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`

echo "Icecast Container Name: " $ICECAST_CONTAINER_NAME
echo "Icecast Host: " $ICECAST_HOST
echo "Icecast Port: " $ICECAST_PORT

sudo docker kill $LIQUIDSOAP_CONTAINER_NAME
sudo docker rm $LIQUIDSOAP_CONTAINER_NAME

cat >./liquidsoap.liq <<END
#!/usr/bin/liquidsoap

set("log.level", 4)
set("log.file", false)
set("log.stdout", true)

enable_replaygain_metadata()

offline_file = single("$OFFLINE_FILE")

high_frequency = playlist("$MOUNT_MUSIC_DIRECTORY/Icecast Groove/High Frequency Grooves")
mid_frequency = playlist("$MOUNT_MUSIC_DIRECTORY/Icecast Groove/Filler Grooves")
low_frequency = playlist("$MOUNT_MUSIC_DIRECTORY/Icecast Groove/Very Rare Grooves")
interludes = playlist("$MOUNT_MUSIC_DIRECTORY/Icecast Groove/Interludes")

chill = playlist("$MOUNT_MUSIC_DIRECTORY/Icecast Chill")

pre_radio = random(weights=[1,1,1,1], [high_frequency, mid_frequency, low_frequency, interludes])
groove_radio = fallback(track_sensitive = false, [pre_radio, offline_file])
groove_radio = amplify(1., override="replay_gain", groove_radio)

chill_radio = fallback(track_sensitive = false, [chill, offline_file])
chill_radio = amplify(1., override="replay_gain", chill_radio)

output.icecast(%vorbis,
    host = "$ICECAST_HOST", port = $ICECAST_PORT,
    password = "$ICECAST_SOURCE_PASSWORD", mount = "$GROOVE_MOUNT_POINT",
    groove_radio)

output.icecast(%vorbis,
    host = "$ICECAST_HOST", port = $ICECAST_PORT,
    password = "$ICECAST_SOURCE_PASSWORD", mount = "$CHILL_MOUNT_POINT",
    chill_radio)

END

sudo docker run \
    -p $LIQUIDSOAP_PORT:$LIQUIDSOAP_PORT \
    --name $LIQUIDSOAP_CONTAINER_NAME \
    -v `pwd`/liquidsoap.liq:/tmp/config.liq \
    -v $HOST_MUSIC_DIRECTORY:$MOUNT_MUSIC_DIRECTORY \
    -d moul/liquidsoap \
    sudo -H -u www-data bash -c 'liquidsoap --debug --verbose /tmp/config.liq'

sleep 1
LIQUIDSOAP_HOST=`sudo docker inspect $LIQUIDSOAP_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`

echo "Liquidsoap Container Name: " $LIQUIDSOAP_CONTAINER_NAME
echo "Liquidsoap Host: " $LIQUIDSOAP_HOST
echo "Liquidsoap Port: " $LIQUIDSOAP_PORT
