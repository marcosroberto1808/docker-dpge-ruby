#!/bin/bash

# run uwsgi in background
DOMAIN=`cat /.django` 

source /AppEnv/bin/activate ; uwsgi --ini /${DOMAIN}/cfg/django.ini --uid 1000 --gid 1000 &

# start nginx
exec nginx & 

# start sshd
/usr/sbin/sshd -D