#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

read -s -p 'Please enter the SQL password: ' MYSQL_PASSWORD
echo

read -p 'Please enter the Form Name: ' FORM_NAME

read -p 'Please enter the version: ' FORM_VERSION

query_result=$(mysql -u root -p"${MYSQL_PASSWORD}" -D openmrs -se "SELECT uuid FROM form WHERE name LIKE '%${FORM_NAME}%' AND version = '${FORM_VERSION}';")
my_array=($query_result)

for element in "${my_array[@]}"; do
  query_form_id=$(mysql -u root -p"${MYSQL_PASSWORD}" -D openmrs -se "SELECT form_id FROM form WHERE uuid='${element}';")
  version=$(mysql -u root -p"${MYSQL_PASSWORD}" -D openmrs -se "select version from form where uuid='${element}';")
  mysql -u root -p"${MYSQL_PASSWORD}" -D openmrs -se "delete from form_resource where form_id=${query_form_id};"
  mysql -u root -p"${MYSQL_PASSWORD}" -D openmrs -se "delete from form where form_id = ${query_form_id};"
  rm -rf "/home/bahmni/clinical_forms/${element}.json"
  rm -rf "/home/bahmni/clinical_forms/translations/${element}.json"
  echo -e "${RED}Deleted${NC} ${YELLOW}${version}th${NC} version"
  echo
done

