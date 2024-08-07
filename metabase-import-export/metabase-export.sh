#!/bin/bash

read -p "Enter PostgreSQL host [default: localhost]: " PGHOST
PGHOST=${PGHOST:-localhost}

# Prompt for PostgreSQL username with a default value
read -p "Enter PostgreSQL username [default: metabase]: " PGUSER
PGUSER=${PGUSER:-metabase}

# Prompt for PostgreSQL password
echo -n "Enter metabase user password: "
read -s PGPASSWORD
echo

id=$(PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -t -c "SELECT id FROM metabase_database WHERE name = 'analytics' LIMIT 1;" | xargs)

# Check if ID was fetched successfully
if [ -z "$id" ]; then
  echo "Analytics Database not found :("
  exit 1
fi

current_date=$(date +%Y-%m-%d)

# Define the backup directory
backup_dir="metabase-backup-$current_date"

# Create the backup directory and handle errors
if ! mkdir "$backup_dir"; then
  echo "Failed to create directory '$backup_dir'."
  exit 1
fi
cd "$backup_dir"

# Run the first command
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (SELECT * FROM setting WHERE key IN ('custom-geojson')) TO 'setting.csv' WITH CSV DELIMITER ',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select id,email,first_name,last_name,password,password_salt,date_joined,last_login,is_superuser,is_active,reset_token,reset_triggered,is_qbnewb,login_attributes,updated_at,sso_source,locale,is_datasetnewb from core_user) TO 'core_user.csv' With CSV DELIMITER',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select * from collection) TO 'collection.csv' With CSV DELIMITER',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select * from report_card) TO 'report_card.csv' With CSV DELIMITER',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select id, name from metabase_table where db_id = $id) TO 'metabase_table.csv' With CSV DELIMITER ',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select metabase_field.id, metabase_field.name, metabase_field.table_id from metabase_field inner join metabase_table on metabase_field.table_id = metabase_table.id where metabase_table.db_id = $id) TO 'metabase_field.csv' With CSV DELIMITER ',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select * from report_dashboard) TO 'report_dashboard.csv' With CSV DELIMITER',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select * from report_dashboardcard) TO 'report_dashboardcard.csv' With CSV DELIMITER',' HEADER;"
PGPASSWORD=$PGPASSWORD psql -h "$PGHOST" -U "$PGUSER" -d metabase -c "\COPY (select * from dashboardcard_series) TO 'dashboardcard_series.csv' With CSV DELIMITER',' HEADER;"

# Clear the password variable
unset PGPASSWORD

cd ..
zip -r "$backup_dir.zip" "$backup_dir"
rm -r "$backup_dir"

echo "Data exported successfully."
