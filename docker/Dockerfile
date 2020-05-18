FROM ubuntu:18.04

MAINTAINER psilva.gomes.rogerio@gmail.com

ARG PGPORT
ARG PGVERSAO
ARG CONTRIBS
ARG COMPILAR_CONTRIB
ARG ENVIROMENT
ENV TZ=America/Sao_Paulo
ENV DEBIAN_FRONTEND='noninteractive'
ENV LD_LIBRARY_PATH=/opt/pgsql/${PGVERSAO}/lib:$LD_LIBRARY_PATH
ENV PGDATA=/opt/pgsql/${PGVERSAO}/data

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
    ln -s /bin/bash /bin/sh

RUN useradd postgres

RUN apt-get update && apt install -y wget \
    lsb-core \ 
    tzdata \
    perl \
    libreadline7 \
    libreadline-dev \
    readline-common \
    openssl \
    libssl-dev \
    libxml2 \
    libxml2-dev \
    build-essential \
    zlibc \
    zlib1g \
    zlib1g-dev \
    gettext \
    rsyslog-gnutls 

# Compilando Postgres
RUN wget --quiet -O postgresql-${PGVERSAO}.tar.gz https://ftp.postgresql.org/pub/source/v${PGVERSAO}/postgresql-${PGVERSAO}.tar.gz
RUN mkdir -p /opt/sources && tar -xf postgresql-${PGVERSAO}.tar.gz -C /opt/sources
RUN cd /opt/sources/postgresql-${PGVERSAO} && \
    ./configure --with-openssl --with-libxml --enable-nls --prefix=/opt/pgsql/${PGVERSAO} && \
    make && \
    make install

RUN mkdir -p /opt/pgsql/${PGVERSAO}/data && \
    chown postgres. /opt/pgsql/${PGVERSAO}/data && \
    chmod 700 /opt/pgsql/${PGVERSAO}/data

RUN ln -svf /opt/pgsql/${PGVERSAO}/bin/initdb /usr/local/bin/initdb && \
    ln -svf /opt/pgsql/${PGVERSAO}/bin/postgres /usr/local/bin/postgres && \
    ln -svf /opt/pgsql/${PGVERSAO}/bin/pg_ctl /usr/local/bin/pg_ctl && \
    ln -svf /opt/pgsql/${PGVERSAO}/bin/pg_dump /usr/local/bin/pg_dump && \
    ln -svf /opt/pgsql/${PGVERSAO}/bin/psql /usr/local/bin/psql && \
    ln -svf /opt/pgsql/${PGVERSAO} /opt/pgsql/release 

RUN locale-gen en_US en_US.UTF-8 pt_BR.UTF-8 && \
    dpkg-reconfigure locales

# Compilando contribs
COPY contrib.sh  /tmp/contrib.sh
RUN              /tmp/contrib.sh

# Iniciando cluster (Usuario Postgres)
USER postgres

RUN initdb -D /opt/pgsql/${PGVERSAO}/data

COPY sql         /tmp/sql
COPY run.sh      /tmp/run.sh
RUN              /tmp/run.sh

# Removendo arquivos 
USER root
RUN  rm -rf /tmp/sql && rm -f /tmp/run.sh && rm -f /tmp/contrib.sh

# Iniciando Servico
USER postgres

EXPOSE ${PGPORT}

CMD ["postgres", "-D", "/opt/pgsql/release/data", "-c", "config_file=/opt/pgsql/release/data/postgresql.conf"]
