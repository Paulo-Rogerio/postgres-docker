#!/bin/bash

# Priorizar alguns schemas
PRIORIZAR_SCHEMAS="xxx|yyy|zzz"

# Remove dumps antigos com + de 24 Hrs
if [[ -f "/tmp/G9ZXN9AK.txt" ]] && [[ $(cat /tmp/G9ZXN9AK.txt) == $(date +%Y%m%d) ]]
then
    USAR_CACHE=true
else
    USAR_CACHE=false
    echo $(date +%Y%m%d) > /tmp/G9ZXN9AK.txt
fi

if [[ ${USAR_CACHE} == false ]]
then

    # Remove Dumps antigos
    rm -rf ${DESTINO}/*

    # Todas as bases
    STRING_CONNECT="psql -p ${PORTA_PGSQL_PRODUCTION} -h ${IPADDR_PGSQL_PRODUCTION} -d postgres -U ${USER_BACKUP_PRODUCTION}"
    SQL="SELECT datname FROM pg_database WHERE datname not in ('template0','template1','postgres');"

    for BASE in $(${STRING_CONNECT} -c "${SQL}" -A -t)
    do
        mkdir -p ${DESTINO}/${BASE}/{dados,estrutura}

        # Todos os schemas
        SQL="SELECT s.schema_name FROM information_schema.schemata s
            WHERE s.schema_name NOT ILIKE 'pg_%'
            AND s.schema_name NOT IN ('information_schema')"

        STRING_CONNECT="psql -p ${PORTA_PGSQL_PRODUCTION} -h ${IPADDR_PGSQL_PRODUCTION} -d ${BASE} -U ${USER_BACKUP_PRODUCTION}"    

        for SCHEMA in $(${STRING_CONNECT} -c "${SQL}" -A -t)
        do
            if [[ ${SCHEMA} =~ (${PRIORIZAR_SCHEMAS}) ]];
            then
                pg_dump -f ${DESTINO}/${BASE}/dados/_${SCHEMA}_dados.sql -n ${SCHEMA} -h ${IPADDR_PGSQL_PRODUCTION} -U ${USER_BACKUP_PRODUCTION} ${BASE}
            else
                pg_dump -f ${DESTINO}/${BASE}/dados/${SCHEMA}_dados.sql -n ${SCHEMA} -h ${IPADDR_PGSQL_PRODUCTION} -U ${USER_BACKUP_PRODUCTION} ${BASE}
            fi

            pg_dump -f ${DESTINO}/${BASE}/estrutura/${SCHEMA}_estrutura.sql -n ${SCHEMA} -h ${IPADDR_PGSQL_PRODUCTION} -U ${USER_BACKUP_PRODUCTION} ${BASE} -s

            SQL="SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = '${SCHEMA}'
                    AND table_name = 'schema_migrations');"
                        
            if [[ $(${STRING_CONNECT} -c "${SQL}" -A -t) == t ]]
            then        
                pg_dump -f ${DESTINO}/${BASE}/estrutura/${SCHEMA}_schema_migrations.sql -h ${IPADDR_PGSQL_PRODUCTION} -U ${USER_BACKUP_PRODUCTION} -d ${BASE} -a -n ${SCHEMA} -t ${SCHEMA}.schema_migrations
            fi    

        done
    done

    # Dump Roles
    pg_dumpall -f ${DESTINO}/roles.sql --roles-only -h ${IPADDR_PGSQL_PRODUCTION} -U ${USER_BACKUP_PRODUCTION}

fi