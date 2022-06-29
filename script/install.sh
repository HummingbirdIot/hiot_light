#!/bin/sh

cp ./init.d/hiot_light /etc/init.d/
cp ./script/start.sh /usr/bin/hiot_light_start

/etc/init.d/hiot_light enable
