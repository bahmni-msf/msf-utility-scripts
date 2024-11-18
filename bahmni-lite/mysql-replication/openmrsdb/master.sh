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
# MYSQL_REPLICATION_USER - Replication_User(Created in Master)
# MYSQL_REPLICATION_PASSWORD - Replication_User_Password(Created in Master)
# MYSQL_ROOT_USER - Mysql_Root_Username(Slave root username)
# MYSQL_ROOT_PASSWORD - Mysql_Root_Password(Slave root password)

required_vars=("MYSQL_REPLICATION_USER" "MYSQL_REPLICATION_PASSWORD" "MYSQL_ROOT_USER" "MYSQL_ROOT_PASSWORD")
# Check each variable
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo "Error: $var is not set or is empty."
        exit 1
    fi
done

until docker exec bahmni-lite-openmrsdb-1 sh -c "export MYSQL_PWD='$MYSQL_ROOT_PASSWORD'; mysql -u root -e ';'"
do
    echo "Waiting for bahmni-lite-openmrsdb-1 database connection..."
    sleep 4
done

create_slave_user="delete from mysql.user where User='$MYSQL_REPLICATION_USER';FLUSH PRIVILEGES;CREATE USER '$MYSQL_REPLICATION_USER'@'%' IDENTIFIED BY '$MYSQL_REPLICATION_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_REPLICATION_USER'@'%'; FLUSH PRIVILEGES; SHOW MASTER STATUS \\G;"

create_slave_user_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$create_slave_user\""

docker exec bahmni-lite-openmrsdb-1 sh -c "$create_slave_user_cmd"
