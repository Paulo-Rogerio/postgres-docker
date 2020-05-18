#!/usr/bin/env bash
cd $(dirname $0)

#------- Definições Telegram --------
KEY="0123456789:HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
CHATID="-0123456789"
URL="https://api.telegram.org/bot${KEY}/sendMessage"

#-------- Definicoes Postgres -------
PGPORTA=$1
ENVIROMENT=$2
PGVERSAO=$3
COMPILAR_CONTRIB=true
CONTRIBS="dblink,postgres_fdw,unaccent"

#---- Definicoes Dump Production ----
PORTA_PGSQL_PRODUCTION="5432"
IPADDR_PGSQL_PRODUCTION="192.168.100.100"
USER_BACKUP_PRODUCTION="user_backup"
export PGPASSWORD="Uma_Senha_Dificil"

#-------- Definicoes Registry -------
REGISTRY="prgs/postgres-${ENVIROMENT}:${PGVERSAO}"

#------- Configuracões Gerais -------
ORIGEM="/opt/apps/postgres/dump"
CACHE="${ORIGEM}/*/cache/*"
ROLES="${ORIGEM}/*/dump_producao/roles.sql"
DESTINO="../docker/sql"

# Checa se os parametros foram passados
if [[ x"$1" == x ]] || [[ x"$2" == x ]] || [[ x"$3" == x ]];
then
    echo "Não foram passado os parametros esperados pelo script. Processo abortado" > /tmp/msg.txt
    MSG=$(cat /tmp/msg.txt)
    curl -s -d "chat_id=${CHATID}&text=${MSG}&disable_web_page_preview=true&parse_mode=markdown" ${URL} > /dev/null
    exit 1;
fi

# Dump Dados Production
. ./dump.sh

# Ajuste no dump das roles
if [[ $(uname) == "Linux" ]]
then
    # Removendo HASH das Senhas
    sed -i -E "s/PASSWORD 'md5.*'//" ${DESTINO}/roles.sql
    
    # Remove Role (postgres)
    sed -i '/CREATE ROLE postgres;/d' ${DESTINO}/roles.sql
fi

# Build Imagem
cd ../docker
docker build \
--build-arg PGPORT=${PGPORTA} \
--build-arg PGVERSAO=${PGVERSAO} \
--build-arg COMPILAR_CONTRIB=${COMPILAR_CONTRIB} \
--build-arg CONTRIBS=${CONTRIBS} \
--build-arg ENVIROMENT=${ENVIROMENT} \
-t ${REGISTRY} -f Dockerfile .
[[ $? -eq 0 ]] && export STATUS="SUCESSO" || export STATUS="ERRO"
[[ ${STATUS} == "ERRO" ]] && exit 1;

# Push Imagem
docker push ${REGISTRY}
[[ $? -eq 0 ]] && export STATUS="SUCESSO" || export STATUS="ERRO"
[[ ${STATUS} == "ERRO" ]] && exit 1;

# Notificações.
echo "#Docker PostgreSQL - $(date "+%d/%m/%Y")" > /tmp/msg.txt
echo "Banco ${ENVIROMENT} D-1" >> /tmp/msg.txt
echo "Status: ${STATUS} " >> /tmp/msg.txt
echo "-------------------------------" >> /tmp/msg.txt

MSG=$(cat /tmp/msg.txt)
curl -s -d "chat_id=${CHATID}&text=${MSG}&disable_web_page_preview=true&parse_mode=markdown" ${URL} > /dev/null
