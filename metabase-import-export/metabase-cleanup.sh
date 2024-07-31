#!/bin/bash

# Prompt for PostgreSQL connection details
read -p "Enter PostgreSQL host [default: metabasedb]: " PGHOST
PGHOST=${PGHOST:-metabasedb}

# Prompt for PostgreSQL username with a default value
read -p "Enter PostgreSQL username [default: metabase-user]: " PGUSER
PGUSER=${PGUSER:-metabase-user}


# Prompt for PostgreSQL password
echo -n "Enter metabase user password: "
read -s PGPASSWORD
echo

DBNAME="metabase"

docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"DELETE FROM core_user WHERE id != 1;\""
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"SELECT setval(pg_get_serial_sequence('core_user', 'id'), coalesce(max(id)+1, 1), false) FROM core_user;\""

docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"truncate collection cascade\""
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"SELECT setval(pg_get_serial_sequence('collection', 'id'), coalesce(max(id)+1, 1), false) FROM collection;\""

docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"truncate report_card cascade\""
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"SELECT setval(pg_get_serial_sequence('report_card', 'id'), coalesce(max(id)+1, 1), false) FROM report_card;\""
