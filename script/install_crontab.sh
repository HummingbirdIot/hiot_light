#!/bin/sh

crontab -l 2>/dev/null |{ cat; echo "30 4 * * * /usr/bin/hiot_light_start timer"; } |crontab -
