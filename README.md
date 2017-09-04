# soapstorm
I want to use docker containers to build a [rainwave](https://github.com/rmcauley/rainwave)/[liquidsoap](http://savonet.sourceforge.net/)/[icecast](http://icecast.org/) stack.

## install

First, install docker

Then, install some local 'buntu deps

    apt-get install jq

Then, install memcached with

    ./memcached.sh

Then, install postgres with

    ./postgres.sh
