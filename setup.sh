#!/bin/bash

## SETUP INICIAL
__setup_app() {

if [ -z ${DOMAIN} ]; then
    echo "Error - empty domain name!"
    exit 1
fi

#Converter senha com caracteres especiais
GIT_PASS_CONVERT=$(perl -e 'print quotemeta shift(@ARGV)' "${GIT_PASSWORD}")

HOST=`echo ${DOMAIN} | cut -f1 -d '.'`
sed -i "s/DOMAIN/${DOMAIN}/g" /${DOMAIN}/cfg/*
sed -i "s/HOST/${HOST}/g" /${DOMAIN}/cfg/*
sed -i "s/PORT/${PORT}/g" /${DOMAIN}/cfg/*
sed -i "s/APPNAME/${APPNAME}/g" /${DOMAIN}/cfg/*
sed -i "s/SSH_USER/${SSH_USER}/g" /${DOMAIN}/cfg/*
sed -i "s/GIT_USERNAME/${GIT_USERNAME}/g" /${DOMAIN}/code/.git-credentials
sed -i "s/GIT_PASSWORD/${GIT_PASS_CONVERT}/g" /${DOMAIN}/code/.git-credentials

# setup place for our uwsgi socket
mkdir /${DOMAIN}/run/
chown ${SSH_USER}:nginx /${DOMAIN}/run/
chmod 775 /${DOMAIN}/run/

echo "Your project's code is located in: /${DOMAIN}/code/${HOST}/" 

# save used domainname 
echo "${DOMAIN}" > /.django
}

## SSH CONFIG
__ssh_config() {
# Create a user to SSH into as.
USER=`echo ${SSH_USER}`
SSH_USERPASS=`echo ${SSH_PASS}`
echo -e "$SSH_USERPASS\n$SSH_USERPASS" | (passwd --stdin ${USER})
echo ssh ${USER} password: $SSH_USERPASS
}

## GIT REPOSITORIO CLONE
__git_clone() {
REPO_PATH=`echo ${DOMAIN} | cut -f1 -d '.'`
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git config --global credential.helper store"
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git clone ${GIT_REPO} ${REPO_PATH} -b ${GIT_BRANCH}"
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git clone ${GIT_REPO_2} template_central -b ${GIT_BRANCH}"
su - ${SSH_USER} -c "rm /${DOMAIN}/code/${REPO_PATH}/app/assets"
su - ${SSH_USER} -c "ln -s /${DOMAIN}/code/template_central /${DOMAIN}/code/${REPO_PATH}/app/assets"

chown -R ${SSH_USER}:nginx /${DOMAIN}/code/${HOST}/
chmod +x /${DOMAIN}/code/
}

## Instalar Gems
__install_gems() {
REPO_PATH=`echo ${DOMAIN} | cut -f1 -d '.'`
su - ${SSH_USER} -c "cd /${DOMAIN}/code/${REPO_PATH} && bundle install"
}

## Chamar Funcoes
__setup_app
__ssh_config
__git_clone
__install_gems