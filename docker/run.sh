#!/usr/bin/env bash
set -e

# Postgresql.conf

echo " " > /opt/pgsql/${PGVERSAO}/data/postgresql.conf 
echo "listen_addresses = '*'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                 
echo "port = ${PGPORT}" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf
echo "max_connections = 100" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                                
echo "shared_buffers = 32MB" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                                
echo "log_timezone = 'Brazil/East'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf
echo "datestyle = 'iso, mdy'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf
echo "timezone = 'Brazil/East'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf
echo "lc_messages = 'pt_BR.UTF-8'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                          
echo "lc_monetary = 'pt_BR.UTF-8'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                          
echo "lc_numeric = 'pt_BR.UTF-8'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                           
echo "lc_time = 'pt_BR.UTF-8'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf                              
echo "default_text_search_config = 'pg_catalog.portuguese'" >> /opt/pgsql/${PGVERSAO}/data/postgresql.conf

# Pg_Hba.conf
echo "host all  all    0.0.0.0/0  trust" >> /opt/pgsql/${PGVERSAO}/data/pg_hba.conf

# Start
pg_ctl -D /opt/pgsql/${PGVERSAO}/data start

DIR_PATH="/tmp/sql"

# Importando Roles
echo "Importando Roles...."
psql -p ${PGPORT} -U postgres -d postgres < ${DIR_PATH}/roles.sql > /dev/null

for BASE in $(ls ${DIR_PATH} | grep -v roles.sql)
do
    echo "Criando Banco: ${BASE}_${ENVIROMENT}"
    psql -p ${PGPORT} -U postgres -d postgres -c "CREATE DATABASE \"${BASE}_${ENVIROMENT}\";"

    for DIR in $(ls ${DIR_PATH}/${BASE})
    do
	    # Somente Env TEST - Estrutura e Migrates
        if [[ ${ENVIROMENT} == "test" ]] && [[ ${DIR} == "estrutura" ]]
	    then
            # Check is not empty.
            if [[ ! -z $(ls -A ${DIR_PATH}/${BASE}/estrutura) ]]
            then	
                for FILE in $(ls ${DIR_PATH}/${BASE}/estrutura)
                do
                    echo "Importando Arquivo: ${FILE}"
                    psql -p ${PGPORT} -U postgres -d ${BASE}_${ENVIROMENT} < ${DIR_PATH}/${BASE}/estrutura/${FILE} > /dev/null
		        done
		        echo "----------------------------------------"
	        fi
        
        # Demais Envs - Importa Dados
        elif [[ ${ENVIROMENT} != "test" ]] && [[ ${DIR} == "dados" ]]
        then
            # Check is not empty.
            if [[ ! -z $(ls -A ${DIR_PATH}/${BASE}/dados) ]]
            then
                for FILE in $(ls ${DIR_PATH}/${BASE}/dados)
                do
                    echo "Importando Arquivo: ${FILE}"
                    psql -p ${PGPORT} -U postgres -d ${BASE}_${ENVIROMENT} < ${DIR_PATH}/${BASE}/dados/${FILE} > /dev/null
		        done
                echo "----------------------------------------"
	        fi
	    fi
    done
done

# Todos usuarios são Administradores.
psql -p ${PGPORT} -U postgres -d postgres -c "$(psql -p ${PGPORT} -U postgres -d postgres -c "SELECT 'ALTER USER \"' ||  usename  || '\" WITH SUPERUSER CREATEDB CREATEROLE; '
FROM pg_catalog.pg_user" -t -A)"

echo "[SUCESSO]"

# Stop
pg_ctl -m fast -D /opt/pgsql/${PGVERSAO}/data stop
