#!/bin/bash

export MYSQL_ROOT_USER=<Mysql_Root_Username>
export MYSQL_ROOT_PASSWORD=<Mysql_Root_Password>
export MYSQL_SLAVE_USER=<Replication_User>
export MYSQL_SLAVE_PASSWORD=<Replication_User_Password>

until docker exec bahmni-lite-reportsdb-1 sh -c "export MYSQL_PWD=$MYSQL_ROOT_PASSWORD; mysql -u root -e ';'"
do
    echo "Waiting for bahmni-lite-reportsdb-1 database connection..."
    sleep 4
done

create_slave_user="delete from mysql.user where User='$MYSQL_SLAVE_USER';FLUSH PRIVILEGES;CREATE USER '$MYSQL_SLAVE_USER'@'%' IDENTIFIED BY '$MYSQL_SLAVE_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_SLAVE_USER'@'%'; FLUSH PRIVILEGES; SHOW MASTER STATUS \\G;"

create_slave_user_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$create_slave_user\""

docker exec bahmni-lite-reportsdb-1 sh -c "$create_slave_user_cmd"