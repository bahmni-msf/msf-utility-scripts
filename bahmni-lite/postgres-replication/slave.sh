#!/bin/bash

# Check if .env file path is provided
if [ -z "$1" ]; then
    echo "Error: No .env file path provided."
    echo "Usage: $0 <path_to_env_file>"
    exit 1
fi

BAHMNI_DOCKER_ENV_FILE=$1
source ${BAHMNI_DOCKER_ENV_FILE}

function is_container_running() {
    local service_name=$1
    docker ps --filter "name=${service_name}" --filter "status=running" | grep $service_name > /dev/null
    return $?
}

function start_container() {
    local service_name=$1
    log_info "Starting $service_name Container"
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} up -d $service_name
    log_info "Waiting for $service_name container to initialise"
    sleep 60
}

function run_replication_setup() {
    local db_name=$1
    local db_password=$2
    local db_host=$3
    local db_username=$4
    local db_service_name=$5
    local host_db_port=$6
    local db_container_name=$7
    local restart_required=false

    is_container_running $db_service_name
    if [ $? -eq 0 ]; then
        echo "Container $db_service_name is already running."
    else
        echo "Starting container: $db_service_name..."
        start_container $db_service_name
        if [ $? -ne 0 ]; then
            echo "Error: Failed to start container $db_service_name"
            return 1
        fi
    fi

    echo "Remove exisiting file database '$db_name'"
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} exec -T $db_service_name bash -c "rm -rf /var/lib/postgresql/data/*"
    # docker exec $db_service_name sh -c "rm -rf /var/lib/postgresql/data/*"

    echo "Removing and restore backup from Host, IP: $HOST_IP, PgRole: $SLAVE_DB_ROLE"
    docker exec $db_container_name sh -c "PGPASSWORD='$SLAVE_DB_ROLE_PASSWORD' pg_basebackup -h $HOST_IP -p $host_db_port -U $SLAVE_DB_ROLE -D /var/lib/postgresql/data/ -Fp -Xs -R"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restore backup"
        return 1
    fi

    echo "Restarting container $db_service_name..."
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} restart --no-deps $db_service_name
    if [ $? -ne 0 ]; then
        echo "Error: Failed to restart container $db_service_name"
        return 1
    fi

    echo "Setup done"
}

run_replication_setup $METABASE_DB_NAME $METABASE_DB_PASSWORD $METABASE_DB_HOST $METABASE_DB_USER "metabasedb" $METABASE_DB_HOST_PORT "bahmni-lite-metabasedb-1"
run_replication_setup $MART_DB_NAME $MART_DB_PASSWORD $MART_DB_HOST $MART_DB_USERNAME "martdb" $MART_DB_HOST_PORT "bahmni-lite-martdb-1"
