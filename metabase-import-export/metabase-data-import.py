import csv
import json
import os
import sys
import re
import pdb

class CollectionImport:
    # File paths
    SOURCE_PATH = './source/'
    TARGET_PATH = './target/'
    SOURCE_FILES = {
        'metabase_table': 'metabase_table.csv',
        'metabase_field': 'metabase_field.csv',
        'user': 'core_user.csv',
        'collection': 'collection.csv',
        'report_card': 'report_card.csv'
    }
    TARGET_FILES = {
        'metabase_table': 'metabase_table.csv',
        'metabase_field': 'metabase_field.csv',
        'user': 'core_user.csv',
        'collection': 'collection.csv',
        'report_card': 'report_card.csv'
    }

    # Constants
    DATABASE_ID = 3
    DEFAULT_CREATOR_ID = 1

    def __init__(self, source_path=None, target_path=None):
        csv.field_size_limit(sys.maxsize)
        if source_path:
            self.SOURCE_PATH = source_path
        if target_path:
            self.TARGET_PATH = target_path

        self.SOURCE_DATA = {key: self.load_csv(os.path.join(self.SOURCE_PATH, file)) for key, file in self.SOURCE_FILES.items()}
        self.TARGET_DATA = {key: self.load_csv(os.path.join(self.TARGET_PATH, file)) for key, file in self.TARGET_FILES.items()}

    @staticmethod
    def load_csv(file_path):
        if os.path.exists(file_path):
            try:
                with open(file_path, newline='') as csvfile:
                    return list(csv.DictReader(csvfile))
            except Exception as e:
                print(f"Error loading {file_path}: {e}")
                return []
        else:
            print(f"File {file_path} does not exist. Skipping.")
            return []

    def generate_user(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_user.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['user']:
                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def generate_collection(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_collection.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA.get('collection', []):
                if row.get('personal_owner_id'):
                    target_user = self.find_entity('user', row['personal_owner_id'])
                    if target_user:
                        row['personal_owner_id'] = target_user['id']
                    else:
                        row['personal_owner_id'] = self.DEFAULT_CREATOR_ID
                # print(f"Migrated data for the ID: {row['id']}")
                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_collection_location(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/updated_collection.csv')
        pattern = r'/(\d+)/'
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA.get('collection', []):
                hashed_row = {key: row[key] for key in ('id', 'location')}
                if hashed_row['location']:
                    match = re.search(pattern, hashed_row['location'])
                    if match:
                        collection_id = match.group(1)
                        target_collection = self.find_entity('collection', collection_id)
                        if target_collection:
                            hashed_row['location'] = f"/{target_collection['id']}/"
                    # print(f"Migrated data for the ID: {hashed_row['id']}")
                    csv_writer.writerow(hashed_row.values())

    def generate_report_card(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_report_card.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['report_card']:
                row['database_id'] = self.DATABASE_ID
                if 'table_id' in row:
                    target_table = self.find_entity('metabase_table', row['table_id'])
                    row['table_id'] = target_table['id'] if target_table else None

                if 'dataset_query' in row:
                    parsed_query = json.loads(row['dataset_query'])
                    row['dataset_query'] = json.dumps(self.update_dataset_query(parsed_query))

                if 'visualization_settings' in row:
                    parsed_query = json.loads(row['visualization_settings'])
                    row['visualization_settings'] = json.dumps(self.update_dataset_query(parsed_query))

                if 'result_metadata' in row:
                    parsed_query = json.loads(row['result_metadata'])
                    row['result_metadata'] = json.dumps(self.update_dataset_query(parsed_query))

                target_user = self.find_entity('user', row['creator_id'])
                row['creator_id'] = target_user['id'] if target_user else self.DEFAULT_CREATOR_ID

                target_collection = self.find_entity('collection', row['collection_id'])
                if target_collection:
                    row['collection_id'] = target_collection['id']

                row['name'] = row['name'].replace('\t', '')

                # print(f"Migrated data for the ID: {row['id']}")
                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_report_card(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/updated_report_card.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['report_card']:
                try:
                    hashed_row = {key: row[key] for key in ('id', 'dataset_query', 'visualization_settings', 'result_metadata')}

                    source_report = self.find_entity('report_card', hashed_row['id'])
                    if source_report:
                        hashed_row['id'] = source_report['id']

                    if 'dataset_query' in hashed_row:
                        parsed_query = json.loads(hashed_row['dataset_query'])
                        hashed_row['dataset_query'] = json.dumps(self.update_dataset_query(parsed_query))

                    if 'visualization_settings' in hashed_row:
                        parsed_vs = json.loads(hashed_row['visualization_settings'])
                        hashed_row['visualization_settings'] = json.dumps(self.update_dataset_query(parsed_vs))

                    if 'result_metadata' in hashed_row:
                        parsed_rs = json.loads(hashed_row['result_metadata'])
                        for result_data in parsed_rs:
                            if 'id' in result_data:
                                target_field = self.find_entity('metabase_field', result_data['id'])
                                if target_field:
                                    result_data['id'] = target_field['id']
                        hashed_row['result_metadata'] = json.dumps(self.update_dataset_query(parsed_rs))

                    # print(f"Migrated data for the ID: {hashed_row['id']}")
                    csv_writer.writerow(hashed_row.values())
                except Exception as error:
                    print(f"Error: {error}")

    def update_dataset_query(self, data):
        try:
            if isinstance(data, dict):
                for key, value in data.items():
                    if key == 'source-table':
                        data[key] = self.process_source_table(value)
                    elif key == 'database':
                        data[key] = self.DATABASE_ID if value > 0 else value
                    elif isinstance(value, (list, dict)):
                        data[key] = self.update_dataset_query(value)
            elif isinstance(data, list):
                if len(data) > 1 and data[0] in ['field', 'field-id'] and not isinstance(data[1], list):
                    target_field = self.find_entity('metabase_field', data[1])
                    if target_field:
                        data[1] = target_field['id']
                else:
                    data = [self.update_dataset_query(item) for item in data]
            return data
        except Exception as e:
            print(f"Failed: {e}")
            return data

    def process_source_table(self, value):
        if isinstance(value, str) and 'card__' in value:
            parts = value.split('__')
            if len(parts) > 1:
                entity_id = parts[-1]
                target_entity = self.find_entity('report_card', entity_id)
                return f"card__{target_entity['id']}" if target_entity else value
        else:
            target_entity = self.find_entity('metabase_table', value)
            return target_entity['id'] if target_entity else value

    def find_entity(self, entity_type, id):
        source_data = self.SOURCE_DATA.get(entity_type)
        if not source_data:
            return None

        entity = next((row for row in source_data if row.get('id') == str(id)), None)
        if not entity:
            return None

        target_data = self.TARGET_DATA.get(entity_type)
        if not target_data:
            return None

        if entity_type in ['metabase_table', 'collection']:
            return next((row for row in target_data if row.get('name') == entity.get('name')), None)
        elif entity_type == 'metabase_field':
            target_table = self.find_entity('metabase_table', entity.get('table_id'))
            if not target_table:
                return None
            return next((row for row in target_data if row.get('name') == entity.get('name') and row.get('table_id') == target_table.get('id')), None)
        elif entity_type == 'user':
            return next((row for row in target_data if row.get('email') == entity.get('email')), None)
        elif entity_type == 'report_card':
            return next((row for row in target_data if row.get('name', '').replace('\t', '') == entity.get('name', '').replace('\t', '')), None)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        # print("Usage: python script.py [source_path] [target_path] [generate_user|generate_collection|update_collection|generate_report_card|update_report_card]")
        sys.exit(1)

    command = sys.argv[1]
    source_path = sys.argv[2]
    target_path = sys.argv[3]

    ci = CollectionImport(source_path, target_path)

    if command == "generate_user":
        ci.generate_user()
    elif command == "generate_collection":
        ci.generate_collection()
    elif command == "update_collection":
        ci.update_collection_location()
    elif command == "generate_report_card":
        ci.generate_report_card()
    elif command == "update_report_card":
        ci.update_report_card()
    else:
        print("Invalid command. Use 'generate_user', 'generate_collection', 'update_collection', 'generate_report_card', or 'update_report_card'.")
        sys.exit(1)
