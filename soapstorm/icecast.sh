#!/bin/bash

SOAPSTORM_NAME=${SOAPSTORM_NAME:-Marquee}
SOAPSTORM_EMAIL=${SOAPSTORM_EMAIL:-curtis@lassam.net}
SOAPSTORM_DOMAIN=${SOAPSTORM_DOMAIN:-radio.marquee.click}
SOAPSTORM_STREAM=${SOAPSTORM_STREAM:-Marquee}

SOAPSTORM_USER=${SOAPSTORM_USER:-user}
SOAPSTORM_PASS=${SOAPSTORM_PASS:-pass}

ICECAST_CONTAINER_NAME=${ICECAST_CONTAINER_NAME:-soapstorm-icecast}
ICECAST_USER=${ICECAST_USER:-soapy}
ICECAST_PASSWORD=${ICECAST_PASSWORD:-stormy}
ICECAST_PORT=8000

sudo docker kill $ICECAST_CONTAINER_NAME
sudo docker rm $ICECAST_CONTAINER_NAME

cat >./icecast.xml <<END
<!--
    This is a sample Icecast2 server config you can use to get started
    with Rainwave.
    Please reference icecast.org for full documentation about this file.
    This config file is based off the default config for a Debian install.
    If you have custom compiled your own or use a different distro,
    please check to make sure the path settings for file serving are correct.
-->

<icecast>
    <location>$SOAPSTORM_NAME</location>
    <admin>$SOAPSTORM_EMAIL</admin>

    <limits>
        <clients>100</clients>
        <sources>30</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>10</source-timeout>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        <source-password>$ICECAST_PASSWORD</source-password>
        <relay-password>$ICECAST_PASSWORD</relay-password>

        <admin-user>$ICECAST_PASSWORD</admin-user>
        <admin-password>$ICECAST_PASSWORD</admin-password>
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
        <mount-name>/radio.mp3</mount-name>
        <public>1</public>
        <!-- This authentication block is what allows Rainwave to perceive
                users as tuned in or not. -->
        <authentication type="url">
            <option name="listener_add" value="http://localhost/api4/listener_add/1" />
            <option name="listener_remove" value="http://localhost/api4/listener_remove/1" />
            <option name="username" value="$SOAPSTORM_USER"/>
            <option name="password" value="$SOAPSTORM_PASS"/>
            <option name="auth_header" value="icecast-auth-user: 1"/>
        </authentication>
        <stream-name>$SOAPSTORM_NAME</stream-name>
        <stream-description>Streaming music.</stream-description>
        <stream-url>http://$DOMAIN</stream-url>
    </mount>
</icecast>
END

sudo docker run -p $ICECAST_PORT:$ICECAST_PORT --name $ICECAST_CONTAINER_NAME -v `pwd`/icecast.xml:/etc/icecast2/icecast.xml -d moul/icecast
sleep 1
ICECAST_HOST=`sudo docker inspect $ICECAST_CONTAINER_NAME | jq '.[0]["NetworkSettings"]["IPAddress"]' | sed -e 's/^"//' -e 's/"$//'`

echo "Icecast Container Name: " $ICECAST_CONTAINER_NAME
echo "Icecast Host: " $ICECAST_HOST
echo "Icecast Port: " $ICECAST_PORT
