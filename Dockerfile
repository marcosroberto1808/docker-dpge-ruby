# Dockerfile by Marcos Roberto

# Variaveis de ambiente
FROM centos:centos7
LABEL author="marcos.roberto@defensoria.ce.def.br"
ENV AMBIENTE "development"
ENV APPNAME "sge.devel"
ENV ROOT_DOMAIN "defensoria.ce.def.br"
ENV DOMAIN "${APPNAME}.${ROOT_DOMAIN}"
ENV PORT 8080
ENV GIT_REPO "https://github.com/dpgeceti/sistema-gerenciamanto-estagiario.git"
ENV GIT_USERNAME "<git user>"
ENV GIT_PASSWORD "<git password>"
RUN echo ${DOMAIN}
RUN echo ${GIT_REPO}

# Acesso SSH
ENV SSH_USER defensoria
ENV SSH_PASS dpgeceti
RUN yum -y update; yum clean all
RUN yum -y install epel-release openssh-server passwd
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' 
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' 

# Dependencias PYTHON 3.4
RUN yum -y install python34-setuptools; yum clean all
RUN yum -y install python34 python34-devel nginx gcc unzip wget git
RUN easy_install-3.4 pip

# Virtualenv
RUN pip install virtualenv
RUN virtualenv -p python3 /AppEnv

# Adicionar arquivos
RUN mkdir -p /${DOMAIN}/cfg/
RUN mkdir -p /${DOMAIN}/logs/
COPY ./arquivos/nginx.conf /${DOMAIN}/cfg/
COPY ./arquivos/django.params /${DOMAIN}/cfg/
COPY ./arquivos/django.ini /${DOMAIN}/cfg/
COPY ./arquivos/.env /${DOMAIN}/cfg/
COPY ./arquivos/static.zip /${DOMAIN}/cfg/

# define mountable dirs
VOLUME ["/var/log/nginx"]

# Add Usuario SSH e arquivos para autenticacao do GIT
RUN adduser --home=/${DOMAIN}/code -u 1000 ${SSH_USER}
COPY ./arquivos/.git-credentials /${DOMAIN}/code/
RUN chown ${SSH_USER}:${SSH_USER} /${DOMAIN}/code/.git-credentials

# Arquivos de configuracao diversos
RUN ln -s /${DOMAIN}/cfg/django.params /etc/nginx/conf.d/
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_orig
RUN ln -s /${DOMAIN}/cfg/nginx.conf /etc/nginx/

# Copiando scripts principais e criando arquivos de log
COPY run.sh /run.sh
COPY setup.sh /setup.sh
RUN chown ${SSH_USER}:nginx /*.sh
RUN touch /${DOMAIN}/logs/${APPNAME}.access.log
RUN touch /${DOMAIN}/logs/${APPNAME}.error.log
RUN touch /${DOMAIN}/logs/${APPNAME}.uwsgi.log
RUN chown -R ${SSH_USER}:nginx /${DOMAIN}
RUN chmod 775 /*.sh
RUN /setup.sh

## Iniciar Tudo
CMD ["/run.sh"]

