# Docker PostgreSQL - Criando Ambientes Dinamicamente.

Em ambiente de desenvolvimento é necessários termos vários ambientes, simular a sua aplicação implica diretamente em ter múltiplos bancos, cada qual com seu respectivo papel.
- Banco de Teste
- Banco de Homologacao
- Banco de Staging
- Banco de Produção

A finalidade desse projeto é ajudar seu time a manter atualizada várias réplicas do seu banco PostgreSQL, além de auxiliar no processo de upgrade do Banco. 

## O que esse Script faz

Permitir compilar a versão do PostgreSQL desejada, bem como compilar as contribs utilizadas pela sua empresa, personalizar porta que o serviço ficará listen, importar os dados e em ambiente de ***TEST*** criar o banco apenas o banco + estrutura de dados.

## Ferramentas Necessárias

Para reproduzir esse tutorial em seu ambiente será necessário os seguintes produtos configurados:

- Servidor Linux com Docker instalado
- Registry ( publico / privado )
- Banco de Produção - PostgreSQL 

## Banco em Produção

O seu servidor do PostgreSQL ```PRODUÇÃO``` deverá ter uma conta pre-configurada para que a imagem possa coletar o ```dump``` necessário para gerar as imagens.

```sql
CREATE ROLE user_backup WITH
	LOGIN
	SUPERUSER
	CREATEDB
	CREATEROLE
	INHERIT
	NOREPLICATION
	CONNECTION LIMIT -1
	PASSWORD 'Uma_Senha_Dificil';
COMMENT ON ROLE user_backup IS 'Usuário Backup ';
```

## Registry

O serviço de ```Registry``` é onde suas imagens ficaram armazenadas, é totalmente aconselhado que se tenha um registry privado. Se vc usa ```Gitlab Community``` pode habilitar esse recurso em seu servidor Gitlab.

### Adequando Script

O Script ```bash/gerar_imagem.sh``` contém alguns parâmetros que devem ser adequado para atender as necessidades do seu ambiente.

Definir um bot no telegram e especificar uma ***KEY*** e um ***CHATID*** para receber as notificações.

```bash
#------- Definições Telegram --------
KEY="0123456789:HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
CHATID="-0123456789"
```

A imagem docker irá compilar o postgres e as contribs necessárias que sua aplicação precisa. Para personalizar quais contribs compiladar, basta adiciona-las na variável ***CONTRIBS***.

```bash
#-------- Definicoes Postgres -------
CONTRIBS="dblink,postgres_fdw,unaccent"
```

Defina suas credencias de acesso ao ***BANCO DE PRODUÇÃO*** para que o script possa fazer dump, e que de preferencia aponte para um ***BANCO SLAVE***. Essas variáveis são usada somente para fazer ***DUMP***. Caso sua empresa já possua um rotina de dump diário, pode-se adequar o conteúdo deste script para apenas fazer um ***SCP*** dos dumps já feito para o servidor que executa a criação das imagens.    

```bash
#---- Definicoes Dump Production ----
PORTA_PGSQL_PRODUCTION="5432"
IPADDR_PGSQL_PRODUCTION="192.168.100.100"
USER_BACKUP_PRODUCTION="user_backup"
export PGPASSWORD="Uma_Senha_Dificil"
```

Aqui terá que definir onde a imagem fará ***PUSH*** das imagens geradas. Se usar um ***REGISTRY PRIVADO*** essa URL será algo do tipo ```registry.empresa.com.br/docker/postgres-${ENVIROMENT}:${PGVERSAO}```
```bash
#-------- Definicoes Registry -------
REGISTRY="prgs/postgres-${ENVIROMENT}:${PGVERSAO}"
```

### Priorizar Alguns Schemas Durante Importação

É muito comum usarmos vários ***SCHEMAS*** no PostgreSQL para melhor organizarmos nossa estrutura de dados. E para evitar duplicar dados, muitas vezes criamos ***REFERENCIAS*** de outras tabelas pertencentes a outros schemas, com isso ao voltar um dump de determinados banco você deve priorizar quais schemas devem ser importados primeiro para evitar erros. 

Ex: Supohamos que tenha um banco chamado ***PROD*** que contenha os seguintes schemas ( rh, erp ). No schema ```erp.pessoa```, possui uma coluna chamada ```usuario_id``` que faz refência a ```rh.usuario``` 

Ao voltar esse banco de exemplo, preciso que o ***PRIMEIRO SCHEMA*** a ser restaurado seja ***RH*** só depois os demais.   

Para ativar esse recurso no script, deve-se adequar o script ```bash/dump.sh```. Pode encadear os schemas que recebem essas prevalências.

```bash
# Priorizar alguns schemas
PRIORIZAR_SCHEMAS="xxx|yyy|zzz"
```

### Cache do Dump Realizado

Para evitar vários dumps repetidos na criação dos ambientes, foi adotado um recurso de ***CACHE***. Caso haja necessidade de recriar a imagem mais de uma vez no dia devido mudancas ocorridos no ambiente de produção, após a imagem já ter sido gerada em um momento anterior, isso pode ser contornado removendo o arquivo de controle do cache.

***Ex:*** Suponhamos que criou sua imagem as 04:00 , ao chegar para trabalhar sua equipe subiu mudancas as no banco de produção as 09:00. Se vc rodar o script, sem apagar o aquivo de controle de cache, essa novas mudancas não serão adicionadas na nova imagem desejada.

```bash
rm -f /tmp/G9ZXN9AK.txt
```

### Agendar Scripts No Crontab

Pode-se criar um script para envocar o ```bash/gerar_imagem.sh```. Neste script deve-se passar 3 parametros:

* Porta 
* Enviroment
* Versão Postgres

Ao executar o script será criado o banco com o sufixo igual ao do enviroment. Se seu banco chama-se ***banco-xxx*** será criado por exemplo ***banco-xxx-development***

```bash
#!/bin/bash
./gerar_imagem.sh 5432 development 10.8 
./gerar_imagem.sh 5434 staging 10.8
./gerar_imagem.sh 5435 test 10.8
./gerar_imagem.sh 5433 homologacao 11.1
```

### Como Rodar As Imagens

Rodando na máquina local do programador.

```bash
docker run -it -p 5435:5435 prgs/postgres-test:10.8
docker run -it -p 5432:5432 prgs/postgres-development:10.8
```

Caso deseje ter um único servidor compartilhado com toda sua equipe , pode definir um ***docker-compose.yml*** . Para poder executa-lo ```docker-compose up -d```

```yaml
version: "3.4"

services:
  postgresql-development:
    image: prgs/postgres-development:10.8
    container_name: postgresql-development
    ports:
      - 5432:5432
    restart: unless-stopped
```    
