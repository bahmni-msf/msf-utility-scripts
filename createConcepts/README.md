1.Prerequisites

    python 2.7 is required. 

2. Navigate to the folder where the properties.json file is there and update below properties.
   

    "author":"Implementation Engineer",  <This is the name with which the sql change set gets created>
   
    "implementationName": "Default"  <Name of the implementation>
   
    "fileName": "test.xls" <.xls input file name or complete path of the file>
   
    "sheetNumber": 1 <This is sheet number in the .xls>

    "conceptName_column": 2 <This should be the Concept Name column number from .xls sheet>

    "conceptPreferredName_column": 3  <This should be the Preferred Name column number form .xls sheet>

    "conceptMapping_column": 4 <This should be Concept Mapping column number from .xls sheet>

    "conceptDataType_column": 5 <Concept Data Type column nubmer from .xls sheet>

    "conceptOptions_column": 8 <Concept Options column number from .xls sheet>

    "conceptHelpText_column": 14 <Concept Help Text column number from .xls sheet>

    "prefix": "IC" <This can be the name of the form for which we are creating concept for.
                    Eg: IC could be the prefix for the form "Initial Consultation" form>

    "url": "https://demo.mybahmni.org/" <Bahmni env where we want to check duplicate concepts and mappings>

    "userName": "superman" <Login username>

    "password": "Admin123" <Login password>

    "outputFileName": "InitialConsultation"  <Name of the form(without spaces) for which the migartions getting created>

    "mapping_reference_ceil_exclude_list": "CIEL313,CIEL312,CIEL311" <List of duplicate CIEL mappings for which we don't want to add migrations>

    "mapping_reference_msf_internal_exclude_list": "MSFF313,MSFF312,MSFF311" <List of duplicate MSF internal mappings for which we don't want to add migrations>

3. Run the below command to create migrations files. This will create a sql and xml file.
   
        python form_v2.py
   
4. We don't have an API end point to check the duplicate mappings. So this requires below manual check. 


Get the preCondition query from the genearted .xml file.

    eg: select count(*) from concept_reference_term
    where code in
    ("MSFF313","MSFF312","MSFF311","MSFF352","MSFF375","MSFF363","MSFF370","MSFF376","MSFF369")
    and retired = 0
    and concept_source_id = (
    select concept_source_id from concept_reference_source where name = "MSFOCP"  and retired =0
    );
Now replace `count(*)` with `code` in the above sql query and run on the openmrs database. This would give the list of mappings which are already there in openmrs database. Add the list to the either of the below mentioned property. 

    If the mapping are CIEL mappings add the list to the
    "mapping_reference_ceil_exclude_list" in properties.json file
    eg: "mapping_reference_ceil_exclude_list": "CIEL313,CIEL312,CIEL311"

    If the mapping are MSF internal mappings add the list to the
    "mapping_reference_msf_internal_exclude_list" in properties.json file
    eg: "mapping_reference_msf_internal_exclude_list": "MSFF313,MSFF312,MSFF311"
   
5. Now run the below command. This will override the existing migration files with the latest mapping queries.

         python form_v2.py



   
    
