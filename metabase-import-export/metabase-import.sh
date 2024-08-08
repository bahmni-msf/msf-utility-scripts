#!/bin/bash

set -e

read -p "Enter the path to the zip file: " zip_file_path

if [ ! -f "$zip_file_path" ]; then
    echo "File '$zip_file_path' does not exist."
    exit 1
fi

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

# Define database name (make sure this is set correctly)
DBNAME="metabase"  # Set the actual database name

# Fetch ID from PostgreSQL
id=$(docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"SELECT id FROM metabase_database WHERE name = 'mart' LIMIT 1;\"" | xargs)

# Check if ID was fetched successfully
if [ -z "$id" ]; then
    echo "Mart Database not found :("
    exit 1
fi

# Define backup directory
backup_dir="./tmp-metabase-import"

rm -rf "$backup_dir"

mkdir -p "$backup_dir/source"
mkdir -p "$backup_dir/target"

# Extract the zip file
echo "Extracting data from '$zip_file_path' file"
unzip -j "$zip_file_path" -d "$backup_dir/source"

fetch_core_user() {
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select id, email from core_user) TO '/core_user.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/core_user.csv "$backup_dir/target/"
}

fetch_metabase_table() {
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select id, name from metabase_table where db_id = $id) TO '/metabase_table.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/metabase_table.csv "$backup_dir/target/"
}

fetch_metabase_field() {
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select metabase_field.id, metabase_field.name, metabase_field.table_id from metabase_field inner join metabase_table on metabase_field.table_id = metabase_table.id where metabase_table.db_id = $id) TO '/metabase_field.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/metabase_field.csv "$backup_dir/target/"
}

fetch_collection() {
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from collection) TO '/collection.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/collection.csv "$backup_dir/target/"
}

fetch_report_card() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from report_card) TO '/report_card.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/report_card.csv "$backup_dir/target/"
}

fetch_report_dashboard() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from report_dashboard) TO '/report_dashboard.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/report_dashboard.csv "$backup_dir/target/"
}

fetch_report_dashboardcard() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from report_dashboardcard) TO '/report_dashboardcard.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/report_dashboardcard.csv "$backup_dir/target/"
}

fetch_dashboardcard_series() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from dashboardcard_series) TO '/dashboardcard_series.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/dashboardcard_series.csv "$backup_dir/target/"
}

fetch_permissions_group() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from permissions_group) TO '/permissions_group.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/permissions_group.csv "$backup_dir/target/"
}

fetch_permissions() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from permissions) TO '/permissions.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/permissions.csv "$backup_dir/target/"
}

fetch_permissions_group_membership() {
    # Fetch Report Card Data
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from permissions_group_membership) TO '/permissions_group_membership.csv' WITH CSV DELIMITER ',' HEADER;\""
    docker cp bahmni-lite-metabasedb-1:/permissions_group_membership.csv "$backup_dir/target/"
}

import_map() {
    docker cp "$backup_dir/source/setting.csv" bahmni-lite-metabasedb-1:/
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY setting (key, value) FROM 'setting.csv' WITH (FORMAT csv, HEADER);\""
    echo "Maps imported successfully"
}

import_user() {
    # Import Users
    echo "Generating user data to import"
    python3.10 metabase-data-import.py generate_user "$backup_dir/source" "$backup_dir/target/" $id

    docker cp "$backup_dir/target/updated/migrate_user.csv" bahmni-lite-metabasedb-1:/
    echo "Proceeding to import user"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\copy core_user (email,first_name,last_name,password,password_salt,date_joined,last_login,is_superuser,is_active,reset_token,reset_triggered,is_qbnewb,login_attributes,updated_at,sso_source,locale,is_datasetnewb) FROM 'migrate_user.csv' WITH (FORMAT csv);\""

    # Fetch User Data
    fetch_core_user
    echo "User imported successfully"
}

import_collection() {
    # Update Collection
    echo "Generate collection data from source"
    python3.10 metabase-data-import.py generate_collection "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_collection.csv" bahmni-lite-metabasedb-1:/

    # Import Collection
    echo "Importing Collection"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY collection (name,description,color,archived,location,personal_owner_id,slug,namespace,authority_level) FROM '/migrate_collection.csv' WITH (FORMAT csv);\""
}

update_collection_data() {
    fetch_collection

    echo "Updating Collection"
    python3.10 metabase-data-import.py update_collection "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/updated_collection.csv" bahmni-lite-metabasedb-1:/
    docker exec bahmni-lite-metabasedb-1 sh -c "chown postgres:postgres updated_collection.csv"

    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"CREATE TEMP TABLE updated_collection_data (id int, location text); COPY updated_collection_data (id, location) FROM '/updated_collection.csv' WITH (FORMAT csv); UPDATE collection SET location = updated_collection_data.location FROM updated_collection_data WHERE collection.id = updated_collection_data.id;\""

    fetch_collection
}

import_report_card() {
    fetch_metabase_table
    fetch_metabase_field

    # Create Report Card
    echo "Creating Report card"
    python3.10 metabase-data-import.py generate_report_card "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_report_card.csv" bahmni-lite-metabasedb-1:/

    # Import Report Card
    echo "Importing Report Card"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY report_card (created_at,updated_at,name,description,display,dataset_query,visualization_settings,creator_id,database_id,table_id,query_type,archived,collection_id,public_uuid,made_public_by_id,enable_embedding,embedding_params,cache_ttl,result_metadata,collection_position,dataset) FROM '/migrate_report_card.csv' WITH (FORMAT csv);\""

    fetch_report_card
}

update_report_card() {
    fetch_report_card

    # Update Report Card
    echo "Updating Report card"
    python3.10 metabase-data-import.py update_report_card "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/updated_report_card.csv" bahmni-lite-metabasedb-1:/
    docker exec bahmni-lite-metabasedb-1 sh -c "chown postgres:postgres updated_report_card.csv"

    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"CREATE TEMP TABLE updated_report_data (id int, dataset_query text, visualization_settings text, result_metadata text); COPY updated_report_data (id, dataset_query, visualization_settings, result_metadata) FROM '/updated_report_card.csv' WITH (FORMAT csv); UPDATE report_card SET dataset_query = updated_report_data.dataset_query, visualization_settings = updated_report_data.visualization_settings, result_metadata = updated_report_data.result_metadata FROM updated_report_data WHERE report_card.id = updated_report_data.id;\""
}

import_report_dashboard() {
    fetch_report_card

    echo "Generate report_dashboard data from source"
    python3.10 metabase-data-import.py update_report_dashboard "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_report_dashboard.csv" bahmni-lite-metabasedb-1:/

    # Import report_dashboard
    echo "Importing report_dashboard"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY report_dashboard (created_at,updated_at,name,description,creator_id,parameters,points_of_interest,caveats,show_in_getting_started,public_uuid,made_public_by_id,enable_embedding,embedding_params,archived,position,collection_id,collection_position,cache_ttl) FROM '/migrate_report_dashboard.csv' WITH (FORMAT csv);\""
}

import_report_dashboardcard() {
    fetch_report_dashboard

    echo "Generate report_dashboardcard data from source"
    python3.10 metabase-data-import.py update_report_dashboardcard "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_report_dashboardcard.csv" bahmni-lite-metabasedb-1:/

    # Import report_dashboardcard
    echo "Importing report_dashboardcard"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY report_dashboardcard (created_at,updated_at,size_x,size_y,row,col,card_id,dashboard_id,parameter_mappings,visualization_settings) FROM '/migrate_report_dashboardcard.csv' WITH (FORMAT csv);\""
}

import_dashboardcard_series() {
    fetch_report_dashboardcard

    echo "Generate dashboardcard_series data from source"
    python3.10 metabase-data-import.py update_dashboardcard_series "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_dashboardcard_series.csv" bahmni-lite-metabasedb-1:/

    # Import dashboardcard_series
    echo "Importing dashboardcard_series"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY dashboardcard_series (dashboardcard_id, card_id, position) FROM '/migrate_dashboardcard_series.csv' WITH (FORMAT csv);\""
}

import_permissions_group() {
    fetch_permissions_group

    echo "Generate permissions_group data from source"
    python3.10 metabase-data-import.py import_permissions_group "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_permissions_group.csv" bahmni-lite-metabasedb-1:/

    # Import permissions_group
    echo "Importing permissions_group"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY permissions_group (name) FROM '/migrate_permissions_group.csv' WITH (FORMAT csv);\""
}

import_permissions() {
    fetch_permissions_group
    # to ignore if data already exist
    fetch_permissions

    echo "Generate permissions data from source"
    python3.10 metabase-data-import.py import_permissions "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_permissions.csv" bahmni-lite-metabasedb-1:/

    # Import permissions_group
    echo "Importing permissions_group"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY permissions (object, group_id) FROM '/migrate_permissions.csv' WITH (FORMAT csv);\""
}

import_permissions_group_membership() {
    fetch_permissions_group
    # to ignore if data already exist
    fetch_permissions_group_membership

    echo "Generate permissions_group_membership data from source"
    python3.10 metabase-data-import.py import_permissions_group_membership "$backup_dir/source" "$backup_dir/target" $id

    docker cp "$backup_dir/target/updated/migrate_permissions_group_membership.csv" bahmni-lite-metabasedb-1:/

    # Import permissions_group_membership
    echo "Importing permissions_group_membership"
    docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY permissions_group_membership (user_id, group_id) FROM '/migrate_permissions_group_membership.csv' WITH (FORMAT csv);\""
}

import_map
import_user
import_collection
update_collection_data
import_report_card
update_report_card

import_report_dashboard
import_report_dashboardcard
import_dashboardcard_series

import_permissions_group
import_permissions
import_permissions_group_membership

echo "Import completed successfully"

echo "Proceeding to remove temporary data"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_user.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_report_card.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /updated_report_card.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_collection.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /updated_collection.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_report_dashboard.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_report_dashboardcard.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_dashboardcard_series.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_permissions_group.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_permissions.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm /migrate_permissions_group_membership.csv"

rm -rf "$backup_dir"
echo "Temporary data removed"
