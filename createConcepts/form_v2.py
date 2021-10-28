import json
import xlrd
import requests
from requests.auth import HTTPBasicAuth
from datetime import datetime
import time

properties_json = open('properties.json')
properties = json.load(properties_json)
loc = (properties["fileName"])
wb = xlrd.open_workbook(loc)
sheet = wb.sheet_by_index(properties["sheetNumber"] - 1)
name_index = properties["conceptName_column"] - 1
preferredName_index = properties["conceptPreferredName_column"] - 1
mapping_index = properties["conceptMapping_column"] - 1
dataType_index = properties["conceptDataType_column"] - 1
options_index = properties["conceptOptions_column"] - 1
helpText_index = properties["conceptHelpText_column"] - 1
prefix = properties["prefix"]
userName = properties["userName"]
password = properties["password"]
rows=sheet.nrows
add_concept = {}
child_concepts = set()
numeric_concepts = []
add_concept_description = []
csvHeaderSkipped = False
mapping_reference_ceil = set()
mapping_ceil = set()
mapping_reference_msf_internal = set()
mapping_msf_internal = set()
outputFile = open(properties["outputFileName"] + '.sql', 'w')
outputFile.write('set @concept_id = 0;\n')
outputFile.write('set @concept_short_id = 0;\n')
outputFile.write('set @concept_full_id = 0;\n')
outputFile.write('set @count = 0;\n')
outputFile.write('set @uuid = NULL;\n\n')
outputFile.write('#Add Parent Concepts\n')
outputFile1 = open(properties["outputFileName"] + '.xml', 'w')
outputFile1.write('<?xml version="1.0" encoding="UTF-8"?>\n\n')
outputFile1.write('<databaseChangeLog\n')
outputFile1.write('    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"\n')
outputFile1.write('    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n')
outputFile1.write('    xmlns:ext="http://www.liquibase.org/xml/ns/dbchangelog-ext"\n')
outputFile1.write('    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-2.0.xsd\n')
outputFile1.write('    http://www.liquibase.org/xml/ns/dbchangelog-ext http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-ext.xsd">\n\n')
outputFile1.write('    <changeSet id="' + properties["implementationName"] + '_CONFIG_' + datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3] + '" author="' + properties["author"] + '">\n')
outputFile1.write('        <comment>Adding Concepts for ' + properties["outputFileName"] + ' Form</comment>\n')
outputFile1.write('        <sqlFile path="' + properties["outputFileName"] + '/' + properties["outputFileName"] + '.sql"/>\n')
outputFile1.write('    </changeSet>\n\n')
for row in range(0, rows):
    try:
        name = str(sheet.cell_value(row, name_index)).strip()
        preferredName = ""
        mapping = str(sheet.cell_value(row, mapping_index)).strip()
        dataType = str(sheet.cell_value(row, dataType_index)).strip().capitalize() 
        options = str(sheet.cell_value(row, options_index)).strip()
        helpText = str(sheet.cell_value(row, helpText_index)).strip()
        if preferredName_index > -1:
            preferredName = str(sheet.cell_value(row, preferredName_index)).strip()
    except:
        try:
            print ""
            print str(sheet.cell_value(row, 0)).strip()
            try:
                print "Name: " + str(sheet.cell_value(row, name_index)).strip()
            except:
                print "NAME ISSUE"
                continue
            try:
                print "Mapping:" + str(sheet.cell_value(row, mapping_index)).strip()
            except:
                print "MAPPING ISSUE"
                continue
            try:
                print "DataType: " + str(sheet.cell_value(row, dataType_index)).strip().capitalize() 
            except:
                print "DATATYPE ISSUE"
                continue
            try:
                print "Options: " + str(sheet.cell_value(row, options_index))
            except:
                print "OPTIONS ISSUE"
                continue
            try:
                print "HelpText: " + str(sheet.cell_value(row, helpText_index)).strip()
            except:
                print "HELPTEXT ISSUE"
                continue
        except:
            continue
        continue
    if name == "" or dataType == "":
        continue
    if not csvHeaderSkipped:
        csvHeaderSkipped = True
        continue
    if preferredName == "":
        sql='call add_concept(@concept_id,@concept_short_id,@concept_full_id,"' + prefix + ', ' + name + '","' + name + '","' + dataType + '","Misc",false);'
    else:
        sql='call add_concept(@concept_id,@concept_short_id,@concept_full_id,"' + prefix + ', ' + name + '","' + preferredName + '","' + dataType + '","Misc",false);'
    try:
        arr = add_concept[dataType]
        arr.append(sql)
        add_concept[dataType] = arr
    except:
        add_concept[dataType] = [sql]
    if len(helpText) > 0:
        add_concept_description.append('INSERT INTO concept_description (concept_id,description,locale,creator,date_created,changed_by,date_changed,uuid)\nVALUES ((select concept_id from concept_name where name = "' + prefix + ', ' + name + '" and concept_name_type = "FULLY_SPECIFIED" and locale = "en" and voided = 0),\n"' + helpText + '","en",1,now(),NULL,NULL,uuid());\n')
    if dataType == 'Numeric':
        numeric_concepts.append(prefix + ", " + name)
    if mapping.startswith('MSF') or mapping.startswith('MW'):
        mapping_reference_msf_internal.add(mapping)
        mapping_msf_internal.add('call CREATE_REFERENCE_MAPPING_MSFOCP("' + prefix + ', ' + name + '","' + mapping + '");')
    else:
        mapping = str(int(float(mapping)))
        mapping_reference_ceil.add(mapping)
        mapping_ceil.add('call CREATE_REFERENCE_MAPPING_CEIL("' + prefix + ', ' +name + '","' + mapping + '");')
    if len(options) > 0:
        time.sleep(0.01)
        options = options.split(',')
        options_without_mapping = []
        for option in options:
            option_split = option.strip().split('(')
            options_without_mapping.append(option_split[0].strip())
            mapping_id = -1
            try:
                mapping_id = option_split[1].strip()[:-1]
            except:
                # do nothing
            try:
                res = requests.get(properties["url"] + '/openmrs/ws/rest/v1/concept?s=byFullySpecifiedName&locale=en&name=' + option_split[0].strip(), auth=HTTPBasicAuth(userName, password))
                data = res.json()
                if len(data['results']) == 0:
                    child_concepts.add('call add_concept(@concept_id,@concept_short_id,@concept_full_id,"' + option_split[0].strip() + '","' + option_split[0].strip() +'","N/A","Misc",false);')
                    if mapping_id != -1:
                        if mapping_id.startswith('MSF') or mapping_id.startswith('MW'):
                            mapping_reference_msf_internal.add(mapping_id)
                            mapping_msf_internal.add('call CREATE_REFERENCE_MAPPING_MSFOCP("' + option_split[0].strip() + '","' + mapping_id + '");')
                        else:
                            mapping_reference_ceil.add(mapping_id)
                            mapping_ceil.add('call CREATE_REFERENCE_MAPPING_CEIL("' + option_split[0].strip() + '","' + mapping_id + '");')
                elif mapping_id != -1:
                    res = requests.get(properties["url"] + '/openmrs/ws/rest/v1/concept/' + data["results"][0]["uuid"], auth=HTTPBasicAuth(userName, password))
                    data = res.json()
                    existing_mappings = data["mappings"]
                    if mapping_id.startswith('MSF') or mapping_id.startswith('MW'):
                        key = "MSFOCP: " + mapping_id
                        for mapping in existing_mapping:
                            if mapping["display"] == key:
                                continue
                        mapping_reference_msf_internal.add(mapping_id)
                        mapping_msf_internal.add('call CREATE_REFERENCE_MAPPING_MSFOCP("' + option_split[0].strip() + '","' + mapping_id + '");')
                    else:
                        key = "CEIL: " + mapping_id
                        mapping_exist = False
                        for existing_mapping in existing_mappings:
                            if existing_mapping["display"] == key:
                                mapping_exist = True
                                continue
                        if not mapping_exist:
                            mapping_reference_ceil.add(mapping_id)
                            mapping_ceil.add('call CREATE_REFERENCE_MAPPING_CEIL("' + option_split[0].strip() + '","' + mapping_id + '");')
            except:
                child_concepts.add('call add_concept(@concept_id,@concept_short_id,@concept_full_id,"' + option_split[0].strip() + '","' + option_split[0].strip() +'","N/A","Misc",false);')
                if mapping_id != -1:
                    if mapping_id.startswith('MSF') or mapping_id.startswith('MW'):
                        mapping_reference_msf_internal.add(mapping_id)
                        mapping_msf_internal.add('call CREATE_REFERENCE_MAPPING_MSFOCP("' + option_split[0].strip() + '","' + mapping_id + '");')
                    else:
                        mapping_reference_ceil.add(mapping_id)
                        mapping_ceil.add('call CREATE_REFERENCE_MAPPING_CEIL("' + option_split[0].strip() + '","' + mapping_id + '");')
        outputFile1.write('    <changeSet id="' + properties["implementationName"] + '_CONFIG_' + datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3] + '" author="' + properties["author"] + '">\n')
        outputFile1.write('        <preConditions onFail="MARK_RAN">\n')
        outputFile1.write('            <sqlCheck expectedResult="0">\n')
        outputFile1.write('                select count(*) from concept_answer ca\n')
        outputFile1.write('                join\n')
        outputFile1.write('                concept_name cn\n')
        outputFile1.write('                on ca.concept_id = cn.concept_id\n')
        outputFile1.write('                where ca.answer_concept IN (select concept_id from concept_name where name IN\n')
        outputFile1.write('                ("' + '", "'.join(options_without_mapping) + '")\n')
        outputFile1.write('                and concept_name_type = "FULLY_SPECIFIED")\n')
        outputFile1.write('                AND\n')
        outputFile1.write('                cn.concept_id IN (select concept_id from concept_name where name = "'+ prefix + ', ' + name + '");\n')
        outputFile1.write('            </sqlCheck>\n')
        outputFile1.write('        </preConditions>\n')
        outputFile1.write('        <comment>Adding Answers to ' + prefix + ', ' + name + '</comment>\n')
        outputFile1.write('        <sql>\n')
        outputFile1.write('            select concept_id into @concept_id from concept_name where name = "' + prefix + ', ' + name + '" and\n')
        outputFile1.write('            concept_name_type = "FULLY_SPECIFIED" and locale = "en" and voided = 0;\n')
        options_without_mapping_len = len(options_without_mapping)
        for i in range(1, options_without_mapping_len + 1):
            outputFile1.write('            set @child' + str(i) + '_concept_id = 0;\n')
        for i in range(1, options_without_mapping_len + 1):
            outputFile1.write('            select concept_id into @child' + str(i) + '_concept_id from concept_name where name ="' + options_without_mapping[i-1] + '" and concept_name_type ="FULLY_SPECIFIED" and locale ="en" and voided = 0;\n')
        for i in range(1, options_without_mapping_len + 1):
            outputFile1.write('            call add_concept_answer(@concept_id, @child' + str(i) + '_concept_id, '+ str(i) + ');\n')
        outputFile1.write('        </sql>\n')
        outputFile1.write('    </changeSet>\n\n')
dataTypes=add_concept.keys()
for dataType in dataTypes:
    outputFile.write('#Add ' + dataType + ' Concepts')
    outputFile.write('\n')
    arr = add_concept[dataType]
    for sql in arr:
        outputFile.write(sql)
        outputFile.write('\n')
    if dataType == 'Numeric':
        outputFile.write('\n')
        outputFile.write('#Add Numeric concepts to concept Numeric Table\n')
        for numeric_concept in numeric_concepts:
            outputFile.write('INSERT INTO concept_numeric (concept_id,hi_absolute,hi_critical,hi_normal,low_absolute,low_critical,low_normal,units,precise,display_precision)\n')
            outputFile.write('VALUES ((select concept_id from concept_name where name = "' + numeric_concept + '" and concept_name_type = "FULLY_SPECIFIED"  and locale = "en"  and voided = 0),NULL,NULL,NULL,NULL,NULL,NULL,"",1,1);\n')
    outputFile.write('\n')
outputFile.write('#Add Child Concepts\n')
for child_concept in child_concepts:
    outputFile.write(child_concept)
    outputFile.write('\n')
if len(add_concept_description) > 0:
    outputFile.write('\n#Add Help Text to Concepts\n')
    for concept_description in add_concept_description:
        outputFile.write(concept_description)
time.sleep(0.01)
mapping_reference_ceil = mapping_reference_ceil - set(properties["mapping_reference_ceil_exclude_list"].split(","))
outputFile1.write('    <changeSet id="' + properties["implementationName"] + '_CONFIG_' + datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3] + '" author="' + properties["author"] + '">\n')
outputFile1.write('        <preConditions onFail="MARK_RAN">\n')
outputFile1.write('            <sqlCheck expectedResult="0">\n')
outputFile1.write('                select count(*) from concept_reference_term\n')
outputFile1.write('                where code in\n')
outputFile1.write('                ("' + '","'.join(mapping_reference_ceil)  + '")\n')
outputFile1.write('                and retired = 0\n')
outputFile1.write('                and concept_source_id = (\n')
outputFile1.write('                select concept_source_id from concept_reference_source where name = "CEIL"  and retired =0\n')
outputFile1.write('                );\n')
outputFile1.write('            </sqlCheck>\n')
outputFile1.write('        </preConditions>\n')
outputFile1.write('        <comment>Adding CEIL codes to concepts</comment>\n')
outputFile1.write('        <sql>\n')
outputFile1.write('            SELECT concept_source_id INTO @source_id FROM concept_reference_source where name = "CEIL";\n\n')
for mapping_reference in mapping_reference_ceil:
    outputFile1.write('            INSERT INTO concept_reference_term (creator,code,concept_source_id,uuid,date_created) VALUES (1,"' + mapping_reference + '",@source_id,uuid(),now());\n')
for mapping in mapping_ceil:
    outputFile1.write('            ' + mapping + '\n')
outputFile1.write('        </sql>\n')
outputFile1.write('    </changeSet>\n\n')
time.sleep(0.01)
mapping_reference_msf_internal = mapping_reference_msf_internal - set(properties["mapping_reference_msf_internal_exclude_list"].split(","))
outputFile1.write('    <changeSet id="' + properties["implementationName"] + '_CONFIG_' + datetime.utcnow().strftime('%Y%m%d%H%M%S%f')[:-3] + '" author="' + properties["author"] + '">\n')
outputFile1.write('        <preConditions onFail="MARK_RAN">\n')
outputFile1.write('            <sqlCheck expectedResult="0">\n')
outputFile1.write('                select count(*) from concept_reference_term\n')
outputFile1.write('                where code in\n')
outputFile1.write('                ("' + '","'.join(mapping_reference_msf_internal)  + '")\n')
outputFile1.write('                and retired = 0\n')
outputFile1.write('                and concept_source_id = (\n')
outputFile1.write('                select concept_source_id from concept_reference_source where name = "MSFOCP"  and retired =0\n')
outputFile1.write('                );\n')
outputFile1.write('            </sqlCheck>\n')
outputFile1.write('        </preConditions>\n')
outputFile1.write('        <comment>Adding MSFOCP codes to concepts</comment>\n')
outputFile1.write('        <sql>\n')
outputFile1.write('            SELECT concept_source_id INTO @source_id FROM concept_reference_source where name = "MSFOCP";\n\n')
for mapping_reference in mapping_reference_msf_internal:
    outputFile1.write('            INSERT INTO concept_reference_term (creator,code,concept_source_id,uuid,date_created) VALUES (1,"' + mapping_reference + '",@source_id,uuid(),now());\n')
for mapping in mapping_msf_internal:
    outputFile1.write('            ' + mapping + '\n')
outputFile1.write('        </sql>\n')
outputFile1.write('    </changeSet>\n\n')
outputFile1.write('</databaseChangeLog>\n')