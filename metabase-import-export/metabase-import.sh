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


# Import Users
echo "Generating user data to import"
python3.10 metabase-data-import.py generate_user "$backup_dir/source" "$backup_dir/target"
if [ $? -ne 0 ]; then
    echo "Error while generating data for report card"
    exit 1
fi
docker cp "$backup_dir/target/updated/migrate_user.csv" bahmni-lite-metabasedb-1:/
echo "Procedding to import user"
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\copy core_user (email,first_name,last_name,password,password_salt,date_joined,last_login,is_superuser,is_active,reset_token,reset_triggered,is_qbnewb,login_attributes,updated_at,sso_source,locale,is_datasetnewb) FROM 'migrate_user.csv' WITH (FORMAT csv, HEADER);\""

# Fetch User Data
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select id,email from core_user) TO '/core_user.csv' WITH CSV DELIMITER ',' HEADER;\""
docker cp bahmni-lite-metabasedb-1:/core_user.csv "$backup_dir/target"
echo "User imported successfully"

# Update Collection
echo "Generate collection data from source"
python3.10 metabase-data-import.py generate_collection "$backup_dir/source" "$backup_dir/target"
if [ $? -ne 0 ]; then
    echo "Error while generating data for report card"
    exit 1
fi
docker cp "$backup_dir/target/updated/migrate_collection.csv" bahmni-lite-metabasedb-1:/

# Import Collection
echo "Importing Collection"
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY collection (name,description,color,archived,location,personal_owner_id,slug,namespace,authority_level) FROM '/migrate_collection.csv' WITH (FORMAT csv);\""

# Fetch Collection Data
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from collection) TO '/collection.csv' WITH CSV DELIMITER ',' HEADER;\""
docker cp bahmni-lite-metabasedb-1:/collection.csv "$backup_dir/target"

echo "Updating Collection"
python3.10 metabase-data-import.py update_collection "$backup_dir/source" "$backup_dir/target"
if [ $? -ne 0 ]; then
    echo "Error while generating data for collection"
    exit 1
fi
docker cp "$backup_dir/target/updated/updated_collection.csv" bahmni-lite-metabasedb-1:/
docker exec bahmni-lite-metabasedb-1 sh -c "chown postgres:postgres updated_collection.csv"

docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"CREATE TEMP TABLE updated_collection_data (id int, location text); COPY updated_collection_data (id, location) FROM '/updated_collection.csv' WITH (FORMAT csv, HEADER); UPDATE collection SET location = updated_collection_data.location FROM updated_collection_data WHERE collection.id = updated_collection_data.id;\""

# Fetch Collection Data
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from collection) TO '/collection.csv' WITH CSV DELIMITER ',' HEADER;\""
docker cp bahmni-lite-metabasedb-1:/collection.csv "$backup_dir/target"

# Fetch and export Metabase Table and Fields
echo "Fetching Metabase Table and fields"
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select id, name from metabase_table where db_id = $id) TO '/metabase_table.csv' WITH CSV DELIMITER ',' HEADER;\""
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select metabase_field.id, metabase_field.name, metabase_field.table_id from metabase_field inner join metabase_table on metabase_field.table_id = metabase_table.id where metabase_table.db_id = $id) TO '/metabase_field.csv' WITH CSV DELIMITER ',' HEADER;\""

docker cp bahmni-lite-metabasedb-1:/metabase_table.csv "$backup_dir/target/"
docker cp bahmni-lite-metabasedb-1:/metabase_field.csv "$backup_dir/target/"

# Create Report Card
echo "Creating Report card"
python3.10 metabase-data-import.py generate_report_card "$backup_dir/source" "$backup_dir/target"
if [ $? -ne 0 ]; then
    echo "Error while generating data for report card"
    exit 1
fi
docker cp "$backup_dir/target/updated/migrate_report_card.csv" bahmni-lite-metabasedb-1:/

# Import Report Card
echo "Importing Report Card"
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY report_card (created_at,updated_at,name,description,display,dataset_query,visualization_settings,creator_id,database_id,table_id,query_type,archived,collection_id,public_uuid,made_public_by_id,enable_embedding,embedding_params,cache_ttl,result_metadata,collection_position,dataset) FROM '/migrate_report_card.csv' WITH (FORMAT csv);\""

# Fetch Report Card Data
docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"\COPY (select * from report_card) TO 'report_card.csv' With CSV DELIMITER',' HEADER;\""
docker cp bahmni-lite-metabasedb-1:/report_card.csv "$backup_dir/target"

# Update Report Card
echo "Updating Report card"
python3.10 metabase-data-import.py update_report_card "$backup_dir/source" "$backup_dir/target"
if [ $? -ne 0 ]; then
    echo "Error while generating data for report card"
    exit 1
fi
docker cp "$backup_dir/target/updated/updated_report_card.csv" bahmni-lite-metabasedb-1:/

docker exec bahmni-lite-metabasedb-1 sh -c "chown postgres:postgres updated_report_card.csv"

docker exec bahmni-lite-metabasedb-1 sh -c "PGPASSWORD=$PGPASSWORD psql -h $PGHOST -U $PGUSER -d $DBNAME -t -c \"CREATE TEMP TABLE updated_report_data (id int, dataset_query text, visualization_settings text, result_metadata text); COPY updated_report_data (id, dataset_query, visualization_settings, result_metadata) FROM '/updated_report_card.csv' WITH (FORMAT csv, HEADER); UPDATE report_card SET dataset_query = updated_report_data.dataset_query, visualization_settings = updated_report_data.visualization_settings, result_metadata = updated_report_data.result_metadata FROM updated_report_data WHERE report_card.id = updated_report_data.id;\""

echo "Import completed successfully"

echo "Proceeding to remove temporary data"
docker exec bahmni-lite-metabasedb-1 sh -c "rm migrate_report_card.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm updated_report_card.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm migrate_collection.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm updated_collection.csv"
docker exec bahmni-lite-metabasedb-1 sh -c "rm migrate_user.csv"

rm -rf "$backup_dir"
echo "Temporary data removed"
