#!/bin/bash

# Iniciar servicos

# start nginx
exec nginx & 

# start sshd
/usr/sbin/sshd -D