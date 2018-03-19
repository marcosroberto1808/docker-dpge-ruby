# Dockerfile by Marcos Roberto

# Variaveis de ambiente
FROM centos:centos7
LABEL author="marcos.roberto@defensoria.ce.def.br"
ENV TZ=America/Fortaleza
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV AMBIENTE "stage"
ENV DB_HOST "192.168.10.254"
ENV DB_USER "postgres"
ENV DB_PASS "postgres"
ENV APPNAME "sic.devel"
ENV ROOT_DOMAIN "defensoria.ce.def.br"
ENV DOMAIN "${APPNAME}.${ROOT_DOMAIN}"
ENV PORT 8080
ENV GIT_REPO "https://github.com/dpgeceti/sic.git"
ENV GIT_REPO_2 "https://github.com/dpgeceti/template_central.git"
ENV GIT_USERNAME "<git user>"
ENV GIT_PASSWORD "<git password>"
ENV GIT_BRANCH "master"
RUN echo ${DOMAIN}

# Acesso SSH
ENV SSH_USER defensoria
ENV SSH_PASS dpgeceti
RUN yum -y update; yum clean all
RUN yum -y install epel-release openssh-server passwd
RUN mkdir /var/run/sshd
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' 
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' 
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' 

# Dependencias Básicas
RUN yum -y install gcc unzip wget git which patch autoconf \
automake bison bzip2 gcc-c++ libffi-devel libtool readline-devel \
sqlite-devel zlib-devel libyaml-devel openssl-devel \
nodejs npm postgresql-devel
RUN curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
RUN yum -y install nginx passenger passenger-devel 

# Adicionar arquivos
RUN mkdir -p /${DOMAIN}/cfg/
RUN mkdir -p /${DOMAIN}/logs/
COPY ./arquivos/nginx.conf /${DOMAIN}/cfg/
COPY ./projetos/sic.zip /${DOMAIN}/cfg/
COPY ./projetos/template_central.zip /${DOMAIN}/cfg/

# define mountable dirs
VOLUME ["/var/log/nginx"]

# Add Usuario SSH e arquivos para autenticacao do GIT
RUN adduser --home=/${DOMAIN}/code -u 1000 ${SSH_USER}
COPY ./arquivos/.git-credentials /${DOMAIN}/code/
RUN chown ${SSH_USER}:${SSH_USER} /${DOMAIN}/code/.git-credentials

# Dependencias RVM e RUBY
RUN mkdir -p /AppEnv
RUN chown -R ${SSH_USER}:${SSH_USER} /AppEnv
USER ${SSH_USER}
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
RUN /bin/bash -l -c "curl -L get.rvm.io | bash -s stable --rails --autolibs=enabled --path /AppEnv"
RUN /bin/bash -l -c "source ~/.bashrc"
RUN /bin/bash -l -c "rvm install 2.3.0"
RUN /bin/bash -l -c "rvm --default use 2.3.0"
RUN /bin/bash -l -c "gem update --system"

# Arquivos de configuracao nginx
USER root
# RUN ln -s /${DOMAIN}/cfg/passenger.conf /etc/nginx/conf.d/
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf_orig
RUN ln -s /${DOMAIN}/cfg/nginx.conf /etc/nginx/

# Copiando scripts principais e criando arquivos de log
USER root
COPY run.sh /run.sh
COPY setup.sh /setup.sh
RUN chown ${SSH_USER}:nginx /*.sh
RUN touch /${DOMAIN}/logs/${APPNAME}.access.log
RUN touch /${DOMAIN}/logs/${APPNAME}.error.log
# RUN touch /${DOMAIN}/logs/${APPNAME}.uwsgi.log
RUN chown -R ${SSH_USER}:nginx /${DOMAIN}
RUN chmod 775 /*.sh
RUN /setup.sh

# ## Iniciar Tudo
CMD ["/run.sh"]

