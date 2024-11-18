# Mysql and PSQL Replication Setup

### For Master Instance

Add the below variable with respective values in Shell configuration files like .bashrc, .zshrc on the Master Instance

```
export MYSQL_ROOT_USER=Mysql_Root_Username(Slave root username)
export MYSQL_ROOT_PASSWORD=Mysql_Root_Password(Slave root password)

# MYSQL Replication user
export MYSQL_REPLICATION_USER=Replication_User(Created in Master)
export MYSQL_REPLICATION_PASSWORD=Replication_User_Password(Created in Master)

# PSQL Replication user
export SLAVE_DB_ROLE=Replication_User(Created in Master)
export SLAVE_DB_ROLE_PASSWORD=Replication_User_Password(Created in Master)
```

### For Slave Instance

Add the below variable with respective values in Shell configuration files like .bashrc, .zshrc on slace instance

```
export HOST_IP=HOST_IP_OF_MASTER_INSTANCE(Private IP of Master Instance)

export MYSQL_ROOT_USER=Mysql_Root_Username(Slave root username)
export MYSQL_ROOT_PASSWORD=Mysql_Root_Password(Slave root password)

# Exposed Ports from Master Instance
export OPENMRSDB_HOST_PORT=HOST_PORT_OF_MASTER_INSTANCE(Openmrs db external port)
export METABASE_DB_HOST_PORT=HOST_PORT_OF_MASTER_INSTANCE(Metabase db external port)
export MART_DB_HOST_PORT=HOST_PORT_OF_MASTER_INSTANCE(Mart db external port)

# MYSQL Replication user
export MYSQL_REPLICATION_USER=Replication_User(Created in Master)
export MYSQL_REPLICATION_PASSWORD=Replication_User_Password(Created in Master)

# PSQL Replication user
export SLAVE_DB_ROLE=Replication_User(Created in Master)
export SLAVE_DB_ROLE_PASSWORD=Replication_User_Password(Created in Master)
```

Update the `slave.sh` in OpenmrsDB and ReportsDB based on response from the Master.

```
export MASTER_LOG_FILE=<LOG_FILE(Copy from Staus of Master)>
export MASTER_LOG_POS=59<LOG_POS(Copy from Staus of Master)>
```
