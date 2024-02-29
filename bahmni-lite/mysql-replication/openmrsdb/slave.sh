#!/bin/bash

export MASTER_HOST=<HOST_IP_OF_MASTER_INSTANCE(Private IP of EC2 Instance)>
export MASTER_PORT=<HOST_PORT_OF_MASTER_INSTANCE(Openmrs db external port)>
export MASTER_USER=<Replication_User(Created in Master)>
export MASTER_PASSWORD=<Replication_User_Password(Created in Master)>
export MASTER_LOG_FILE=<LOG_FILE(Copy from Staus of Master)>
export MASTER_LOG_POS=59<LOG_POS(Copy from Staus of Master)>
export MYSQL_ROOT_USER=<Mysql_Root_Username(Slave root username)>
export MYSQL_ROOT_PASSWORD=<Mysql_Root_Password(Slave root password)>

mysql_root_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \";\""

until docker exec bahmni-lite-openmrsdb-1 sh -c "$mysql_root_cmd"
do
    echo "Waiting for bahmni-lite-openmrsdb-1 database connection..."
    sleep 4
done

change_master_stmt="STOP SLAVE;CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',MASTER_USER='$MASTER_USER',MASTER_PASSWORD='$MASTER_PASSWORD',MASTER_LOG_FILE='$MASTER_LOG_FILE',MASTER_LOG_POS=$MASTER_LOG_POS,MASTER_PORT=$MASTER_PORT; START SLAVE;"
change_master_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$change_master_stmt\""
docker exec bahmni-lite-openmrsdb-1 sh -c "$change_master_cmd"

docker exec bahmni-lite-openmrsdb-1 sh -c "export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e 'SHOW SLAVE STATUS \G'"