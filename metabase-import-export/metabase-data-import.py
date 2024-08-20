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
        'report_card': 'report_card.csv',
        'report_dashboard': 'report_dashboard.csv',
        'report_dashboardcard': 'report_dashboardcard.csv',
        'dashboardcard_series': 'dashboardcard_series.csv',
        'permissions_group': 'permissions_group.csv',
        'permissions': 'permissions.csv',
        'permissions_group_membership': 'permissions_group_membership.csv'
    }
    TARGET_FILES = {
        'metabase_table': 'metabase_table.csv',
        'metabase_field': 'metabase_field.csv',
        'user': 'core_user.csv',
        'collection': 'collection.csv',
        'report_card': 'report_card.csv',
        'report_dashboard': 'report_dashboard.csv',
        'report_dashboardcard': 'report_dashboardcard.csv',
        'dashboardcard_series': 'dashboardcard_series.csv',
        'permissions_group': 'permissions_group.csv',
        'permissions': 'permissions.csv',
        'permissions_group_membership': 'permissions_group_membership.csv'
    }

    MALAWI_UPDATED_COLUMN_NAME = {
        '12 Palliative Care Assessment': "12 Supportive Care Assessment",
        '15 Medical Social Assessment': "15 Social Assessment",
        '16 Intake for Psychological Assessment': "16 Counsellor Assessment",
        '17 PSA Follow up': "17 Counsellor Follow up",
        '18 PSA Discharge': "18 Counsellor Discharge",
        '19 Surgical Hysterectomy': "19 Cervical Surgical Report",
        '20 Surgical Ovarian': "20 Ovary Surgical Report",
        '21 Surgical Vulvectomy': "21 Vulva Surgical Report",
    }
    # Constants
    DATABASE_ID = 3
    DEFAULT_CREATOR_ID = 1

    def __init__(self, source_path=None, target_path=None, database_id=None):
        csv.field_size_limit(sys.maxsize)
        if source_path:
            self.SOURCE_PATH = source_path
        if target_path:
            self.TARGET_PATH = target_path
        if database_id:
            self.DATABASE_ID = int(database_id)

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
                core_user = self.find_entity('user', row['id'])
                if core_user == None:
                    csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_metabase_field_constraints(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/updated_metabase_fields.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['metabase_field']:
                hashed_row = {key: row[key] for key in ('id', 'base_type', 'semantic_type', 'display_name', 'visibility_type', 'fk_target_field_id')}

                target_field = self.find_entity('metabase_field', hashed_row['id'])
                if target_field:
                    hashed_row['id'] = int(target_field['id'])

                    if 'fk_target_field_id' in hashed_row:
                        fk_target_field = self.find_entity('metabase_field', hashed_row['fk_target_field_id'])
                        hashed_row['fk_target_field_id'] = int(fk_target_field['id']) if fk_target_field else None

                    # print(f"Migrated data for the ID: {hashed_row['id']}")
                    csv_writer.writerow(hashed_row.values())

    def generate_collection(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_collection.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA.get('collection', []):
                if row.get('personal_owner_id'):
                    target_user = self.find_entity('user', row['personal_owner_id'])
                    if target_user:
                        row['personal_owner_id'] = int(target_user['id'])
                    else:
                        row['personal_owner_id'] = self.DEFAULT_CREATOR_ID
                # print(f"Migrated data for the ID: {row['id']}")
                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_collection_location(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/updated_collection.csv')
        pattern = r'\d+'
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA.get('collection', []):
                hashed_row = {key: row[key] for key in ('id', 'location')}
                target_data = self.find_entity('collection', int(hashed_row['id']))

                if target_data:
                    hashed_row['id'] = int(target_data['id'])

                if hashed_row['location'] and hashed_row['location'] != '/':
                    matches = re.findall(pattern, hashed_row['location'])
                    # Loop through each match and replace with custom logic
                    for collection_id in matches:
                        target_collection = self.find_entity('collection', int(collection_id))
                        if target_collection:
                            hashed_row['location'] = hashed_row['location'].replace(collection_id, target_collection['id'], 1)
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
                    row['table_id'] = int(target_table['id']) if target_table else None

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
                row['creator_id'] = int(target_user['id']) if target_user else self.DEFAULT_CREATOR_ID

                target_collection = self.find_entity('collection', row['collection_id'])
                if target_collection:
                    row['collection_id'] = int(target_collection['id'])

                row['name'] = row['name'].replace('\t', '')

                # print(f"Migrated data for the ID: {row['id']}")
                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_report_card(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/updated_report_card.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['report_card']:
                hashed_row = {key: row[key] for key in ('id', 'dataset_query', 'visualization_settings', 'result_metadata')}

                source_report = self.find_entity('report_card', hashed_row['id'])
                if source_report:
                    hashed_row['id'] = int(source_report['id'])

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
                                result_data['id'] = int(target_field['id'])
                    hashed_row['result_metadata'] = json.dumps(self.update_dataset_query(parsed_rs))

                # print(f"Migrated data for the ID: {hashed_row['id']}")
                csv_writer.writerow(hashed_row.values())

    def update_report_dashboard(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_report_dashboard.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['report_dashboard']:
                if row.get('creator_id'):
                    target_user = self.find_entity('user', row['creator_id'])
                    row['creator_id'] = int(target_user['id']) if target_user else self.DEFAULT_CREATOR_ID

                if row.get('collection_id'):
                    target_collection = self.find_entity('collection', row['collection_id'])
                    row['collection_id'] = int(target_collection['id']) if target_collection else None

                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_report_dashboardcard(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_report_dashboardcard.csv')

        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['report_dashboardcard']:
                if row.get('card_id'):
                    target_report = self.find_entity('report_card', row['card_id'])
                    row['card_id'] = int(target_report['id']) if target_report else None

                if row.get('dashboard_id'):
                    target_rd = self.find_entity('report_dashboard', row['dashboard_id'])
                    if target_rd:
                        row['dashboard_id'] = int(target_rd['id'])

                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_dashboardcard_series(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_dashboardcard_series.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['dashboardcard_series']:
                if row.get('card_id'):
                    target_report = self.find_entity('report_card', row['card_id'])
                    row['card_id'] = int(target_report['id']) if target_report else None

                if row.get('dashboardcard_id'):
                    target_rd = self.find_entity('report_dashboardcard', row['dashboardcard_id'])
                    if target_rd:
                        row['dashboardcard_id'] = int(target_rd['id'])

                csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def update_dataset_query(self, data):
        if isinstance(data, dict):
            for key, value in data.items():
                if key == 'source-table':
                    data[key] = self.process_source_table(value)
                elif key == 'source-field':
                    target_field = self.find_entity('metabase_field', value)
                    data[key] = int(target_field['id'])
                elif key == 'database':
                    data[key] = self.DATABASE_ID if value > 0 else value
                elif isinstance(value, (list, dict)):
                    data[key] = self.update_dataset_query(value)
        elif isinstance(data, list):
            if len(data) > 1 and data[0] in ['field', 'field-id'] and not isinstance(data[1], list):
                target_field = self.find_entity('metabase_field', data[1])
                if target_field:
                    data[1] = int(target_field['id'])

                if len(data) > 2 and isinstance(data[2], dict):
                    data[2] = self.update_dataset_query(data[2])
            else:
                data = [self.update_dataset_query(item) for item in data]
        return data

    def import_permissions_group(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_permissions_group.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['permissions_group']:
                permissions_group = self.find_entity('permissions_group', row['id'])
                if permissions_group == None:
                    # row['name'] = row['name'].replace('\t', '')
                    csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def import_permissions(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_permissions.csv')
        target_permissions = self.TARGET_DATA.get('permissions')
        target_collections = self.TARGET_DATA.get('collection')
        used_collections = set()

        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)

            for row in self.SOURCE_DATA['permissions']:
                if 'group_id' in row:
                    target_table = self.find_entity('permissions_group', row['group_id'])
                    row['group_id'] = int(target_table['id'])

                if 'object' in row and "collection" in row['object']:
                    numbers = re.findall(r'\d+', row['object'])
                    for number in numbers:
                        source_data = self.SOURCE_DATA.get('collection')
                        if not source_data:
                            return None

                        entity = next((r for r in source_data if str(r.get('id')) == str(number)), None)
                        target_collection = next(
                            (
                                r for r in target_collections
                                if r.get('slug') == entity.get('slug') and r.get('archived') == entity.get('archived') and (row['group_id'], row['object'].replace(number, r.get('id'))) not in used_collections
                            ), None)

                        if target_collection:
                            row['object'] = row['object'].replace(number, target_collection['id'])
                            used_collections.add((row['group_id'], row['object']))

                elif 'object' in row and "db" in row['object']:
                    numbers = re.findall(r'\d+', row['object'])
                    for number in numbers:
                        db_id = int(number)
                        if db_id == 2:
                            row['object'] = row['object'].replace(number, str(self.DATABASE_ID))

                premission = next((target_row for target_row in target_permissions if target_row.get('object') == row['object'] and int(target_row.get('group_id')) == int(row['group_id']) ), None)
                if premission == None:
                    csv_writer.writerow([value for key, value in row.items() if key != 'id'])

    def import_permissions_group_membership(self):
        os.makedirs(os.path.join(self.TARGET_PATH, 'updated'), exist_ok=True)
        file_path = os.path.join(self.TARGET_PATH, 'updated/migrate_permissions_group_membership.csv')
        with open(file_path, 'w', newline='') as csvfile:
            csv_writer = csv.writer(csvfile)
            for row in self.SOURCE_DATA['permissions_group_membership']:

                if 'group_id' in row:
                    target_permissions_group = self.find_entity('permissions_group', row['group_id'])
                    row['group_id'] = int(target_permissions_group['id'])

                if 'user_id' in row:
                    target_user = self.find_entity('user', row['user_id'])
                    row['user_id'] = int(target_user['id'])

                target_data = self.TARGET_DATA.get('permissions_group_membership')
                premission_group_mem = next((target_row for target_row in target_data if int(target_row.get('user_id')) == int(row['user_id']) and int(target_row.get('group_id')) == int(row['group_id']) ), None)

                if premission_group_mem == None:
                    csv_writer.writerow([value for key, value in row.items() if key != 'id'])


    def process_source_table(self, value):
        if isinstance(value, str) and 'card__' in value:
            parts = value.split('__')
            if len(parts) > 1:
                entity_id = parts[-1]
                target_entity = self.find_entity('report_card', entity_id)
                return f"card__{target_entity['id']}" if target_entity else None
        else:
            target_entity = self.find_entity('metabase_table', value)
            return int(target_entity['id']) if target_entity else None

    def find_entity(self, entity_type, id):
        source_data = self.SOURCE_DATA.get(entity_type)
        if not source_data:
            return None

        entity = next((row for row in source_data if str(row.get('id')) == str(id)), None)
        if not entity:
            return None

        target_data = self.TARGET_DATA.get(entity_type)
        if not target_data:
            return None

        if entity_type == 'metabase_table':
            return next((row for row in target_data if row.get('name') == entity.get('name')), None)
        elif entity_type == 'collection':
            return next((row for row in target_data if row.get('slug') == entity.get('slug') and row.get('archived') == entity.get('archived')), None)
        elif entity_type == 'metabase_field':
            target_table = self.find_entity('metabase_table', entity.get('table_id'))
            if not target_table:
                return None
            return next((row for row in target_data if row.get('name') == entity.get('name') and row.get('table_id') == target_table.get('id')), None)
        elif entity_type == 'user':
            return next((row for row in target_data if row.get('email') == entity.get('email')), None)
        elif entity_type == 'report_card':
            return next((row for row in target_data if row.get('name', '').replace('\t', '') == entity.get('name', '').replace('\t', '') and row.get('archived') == entity.get('archived')), None)
        elif entity_type == 'report_dashboard':
            target_name = entity.get('name', '').replace('\t', '')
            target_collection = self.find_entity('collection', entity.get('collection_id'))
            target_collection_id = target_collection.get('id') if target_collection else None
            matching_row = None
            for row in target_data:
                if row.get('name', '').replace('\t', '') == target_name and row.get('archived') == entity.get('archived'):
                    if target_collection_id:
                        if row.get('collection_id') == target_collection_id:
                            matching_row = row
                            break
                    else:
                        matching_row = row
                        break
            return matching_row
        elif entity_type == 'report_dashboardcard':
            target_card = self.find_entity('report_card', entity.get('card_id'))
            target_dashboard = self.find_entity('report_dashboard', entity.get('dashboard_id'))

            return next((row for row in target_data if row.get('card_id') == target_card.get('id') and row.get('dashboard_id') == target_dashboard.get('id') and row.get('archived') == entity.get('archived')), None)
        elif entity_type == 'permissions_group':
            return next((row for row in target_data if row.get('name').replace('\t', '') == entity.get('name').replace('\t', '')), None)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        sys.exit(1)

    command = sys.argv[1]
    source_path = sys.argv[2]
    target_path = sys.argv[3]
    database_id = sys.argv[4]

    ci = CollectionImport(source_path, target_path, database_id)

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
    elif command == "update_report_dashboard":
        ci.update_report_dashboard()
    elif command == "update_report_dashboardcard":
        ci.update_report_dashboardcard()
    elif command == "update_dashboardcard_series":
        ci.update_dashboardcard_series()
    elif command == "import_permissions_group":
        ci.import_permissions_group()
    elif command == "import_permissions":
        ci.import_permissions()
    elif command == "import_permissions_group_membership":
        ci.import_permissions_group_membership()
    elif command == "update_metabase_field_constraints":
        ci.update_metabase_field_constraints()
    else:
        print("Invalid command :(")
        sys.exit(1)
