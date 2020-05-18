#!/usr/bin/env bash
set -e

if [[ ${COMPILAR_CONTRIB} == true ]]
then

  IFS=',' read -r -a ARRAY <<< "${CONTRIBS}"

  for i in ${ARRAY[@]}
  do
    echo "Compilando: $i"
    if [[ -d "/opt/sources/postgresql-${PGVERSAO}/contrib/$i" ]]
    then
      cd /opt/sources/postgresql-${PGVERSAO}/contrib/$i
      if [[ $? -eq 0 ]]; then make; else echo "Erro ao compilar - make"; exit 1; fi
      if [[ $? -eq 0 ]]; then make install; echo "Sucesso ao compilar: $i"; cd -; else echo "Erro ao compilar - make install: $i"; exit 1; fi
      echo "================="
    fi
    sleep 1
  done
  
fi  