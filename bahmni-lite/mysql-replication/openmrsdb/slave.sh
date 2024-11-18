#!/bin/bash

# Check if .env file path is provided
if [ -z "$1" ]; then
    echo "Error: No .env file path provided."
    echo "Usage: $0 <path_to_env_file>"
    exit 1
fi

BAHMNI_DOCKER_ENV_FILE=$1
source ${BAHMNI_DOCKER_ENV_FILE}

# NOTE: Make sure to add the below variables in the shell configuration files like .bashrc, .zshrc
# HOST_IP - HOST_IP_OF_MASTER_INSTANCE(Private IP of Master Instance)
# OPENMRSDB_HOST_PORT - HOST_PORT_OF_MASTER_INSTANCE(Openmrs db external port)
# MYSQL_REPLICATION_USER - Replication_User(Created in Master)
# MYSQL_REPLICATION_PASSWORD - Replication_User_Password(Created in Master)
# MYSQL_ROOT_USER - Mysql_Root_Username(Slave root username)
# MYSQL_ROOT_PASSWORD - Mysql_Root_Password(Slave root password)

export MASTER_LOG_FILE=<LOG_FILE(Copy from Staus of Master)>
export MASTER_LOG_POS=59<LOG_POS(Copy from Staus of Master)>

required_vars=("HOST_IP" "OPENMRSDB_HOST_PORT" "MYSQL_REPLICATION_USER" "MYSQL_REPLICATION_PASSWORD" "MYSQL_ROOT_USER" "MYSQL_ROOT_PASSWORD" "MASTER_LOG_FILE" "MASTER_LOG_POS")
# Check each variable
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set or is empty."
        exit 1
    fi
done

mysql_root_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \";\""

until docker exec bahmni-lite-openmrsdb-1 sh -c "$mysql_root_cmd"
do
    echo "Waiting for bahmni-lite-openmrsdb-1 database connection..."
    sleep 4
done

check_slave_status_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e 'SHOW SLAVE STATUS \G'"
slave_status=$(docker exec bahmni-lite-openmrsdb-1 sh -c "$check_slave_status_cmd")

if [[ $slave_status == *"Slave_IO_State"* ]]; then
    echo "Replication is already configured. Current replication status:"
    echo "$slave_status"
    exit 0
else
    echo "Replication not configured. Proceeding with setup."
fi

change_master_stmt="STOP SLAVE;CHANGE MASTER TO MASTER_HOST='$HOST_IP',MASTER_USER='$MYSQL_REPLICATION_USER',MASTER_PASSWORD='$MYSQL_REPLICATION_PASSWORD',MASTER_LOG_FILE='$MASTER_LOG_FILE',MASTER_LOG_POS=$MASTER_LOG_POS,MASTER_PORT=$OPENMRSDB_HOST_PORT; START SLAVE;"
change_master_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$change_master_stmt\""
docker exec bahmni-lite-openmrsdb-1 sh -c "$change_master_cmd"

docker exec bahmni-lite-openmrsdb-1 sh -c "export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e 'SHOW SLAVE STATUS \G'"
