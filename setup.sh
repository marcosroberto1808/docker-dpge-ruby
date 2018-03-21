#!/bin/bash

## SETUP INICIAL
__setup_app() {

if [ -z ${DOMAIN} ]; then
    echo "Error - Nome de domínio vazio!"
    exit 1
fi

#Converter senha com caracteres especiais
GIT_PASS_CONVERT=$(perl -e 'print quotemeta shift(@ARGV)' "${GIT_PASSWORD}")
#Inserindo as variaveis de ambiente nos arquivos de configuracao.
HOST=`echo ${DOMAIN} | cut -f1 -d '.'`
sed -i "s/DOMAIN/${DOMAIN}/g" /${DOMAIN}/cfg/*
sed -i "s/HOST/${HOST}/g" /${DOMAIN}/cfg/*
sed -i "s/PORT/${PORT}/g" /${DOMAIN}/cfg/*
sed -i "s/APPNAME/${APPNAME}/g" /${DOMAIN}/cfg/*
sed -i "s/SSH_USER/${SSH_USER}/g" /${DOMAIN}/cfg/*
sed -i "s/AMBIENTE/${AMBIENTE}/g" /${DOMAIN}/cfg/*
sed -i "s/GIT_USERNAME/${GIT_USERNAME}/g" /${DOMAIN}/code/.git-credentials
sed -i "s/GIT_PASSWORD/${GIT_PASS_CONVERT}/g" /${DOMAIN}/code/.git-credentials

# Configurar local para o uwsgi socket
mkdir /${DOMAIN}/run/
chown ${SSH_USER}:nginx /${DOMAIN}/run/
chmod 775 /${DOMAIN}/run/

echo "Your project's code is located in: /${DOMAIN}/code/${HOST}/" 

# Salvar nome de domínio usado  
echo "${DOMAIN}" > /.django
}

# Clonar repositório do GitHub
__git_clone() {
REPO_PATH=`echo ${DOMAIN} | cut -f1 -d '.'`
echo "Executando git clone do projeto $REPO_PATH" 
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git config --global credential.helper store"
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git clone ${GIT_REPO} ${REPO_PATH} -b ${GIT_BRANCH}"
su - ${SSH_USER} -c "cd /${DOMAIN}/code/ && git clone ${GIT_REPO_2} template_central -b ${GIT_BRANCH}"
# unzip /${DOMAIN}/cfg/sic.zip -d /${DOMAIN}/code/
# unzip /${DOMAIN}/cfg/template_central.zip -d /${DOMAIN}/code/
rm /${DOMAIN}/code/${REPO_PATH}/app/assets
ln -s /${DOMAIN}/code/template_central /${DOMAIN}/code/${REPO_PATH}/app/assets
chown -R ${SSH_USER}:nginx /${DOMAIN}/code/${HOST}/
chmod +x /${DOMAIN}/code/
}

# Instalar Gems e configura as variaveis de banco
__install_gems() {
REPO_PATH=`echo ${DOMAIN} | cut -f1 -d '.'`
echo "Executando a instalacao das Gems : bundle install" 
su - ${SSH_USER} -c "cd /${DOMAIN}/code/${REPO_PATH} && bundle install"
sed -i "s/DB_HOST/${DB_HOST}/g" /${DOMAIN}/code/${REPO_PATH}/config/database.yml
}

## Chamar Funcoes
__setup_app
__git_clone
__install_gems