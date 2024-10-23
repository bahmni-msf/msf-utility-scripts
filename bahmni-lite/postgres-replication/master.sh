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

function log_info() {
    local message=$1
    echo "INFO - ${message}"
}

function log_error() {
    local message=$1
    echo -e "\033[31mERROR - ${message}\033[0m"
}

function start_container() {
    local service_name=$1
    log_info "Starting $service_name Container"
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} up -d $service_name
    log_info "Waiting for $service_name container to initialise"
    sleep 60
}

function create_replication_role() {
    local db_name=$1
    local db_password=$2
    local db_host=$3
    local db_username=$4
    local db_service_name=$5
    local restart_required=false

    is_container_running $db_service_name
    if [ $? -eq 0 ]; then
        log_info "Container $db_service_name is already running."
    else
        log_info "Starting container: $db_service_name..."
        start_container $db_service_name
        if [ $? -ne 0 ]; then
            log_error "Error: Failed to start container $db_service_name"
            return 1
        fi
    fi

    log_info "Creating replication role '$SLAVE_DB_ROLE' in database '$db_name' on host '$db_host'..."
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} exec -T $db_service_name bash -c "PGPASSWORD=$db_password psql -h $db_host -U $db_username -d $db_name -t -c \"CREATE ROLE $SLAVE_DB_ROLE WITH REPLICATION PASSWORD '$SLAVE_DB_ROLE_PASSWORD' LOGIN;\""

    # if [ $? -ne 0 ]; then
    #     log_error "Error: Failed to create replication role in database $db_name"
    #     return 1
    # fi

    log_info "Copying pg_hba.conf to $db_service_name..."
    container_id=$(docker compose ps -q $db_service_name)
    docker cp ./pg_hba.conf $container_id:/var/lib/postgresql/data/

    log_info "Restarting container $db_service_name..."
    docker compose --env-file ${BAHMNI_DOCKER_ENV_FILE} restart --no-deps $db_service_name
    if [ $? -ne 0 ]; then
        log_error "Error: Failed to restart container $db_service_name"
        return 1
    fi

    log_info "Replication role '$SLAVE_DB_ROLE' created successfully in database '$db_name'."
}

create_replication_role $METABASE_DB_NAME $METABASE_DB_PASSWORD $METABASE_DB_HOST $METABASE_DB_USER "metabasedb"
create_replication_role $MART_DB_NAME $MART_DB_PASSWORD $MART_DB_HOST $MART_DB_USERNAME "martdb"
