#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "Upload Files"

login_sf

############################################
# Verify Inputs
############################################

if [ ! -f output/analyzer.id ]; then
    log_error "Analyzer Id missing."
    exit 1
fi

if [ ! -f output/sfca.json ]; then
    log_error "SFCA JSON missing."
    exit 1
fi

ANALYZER_ID=$(cat output/analyzer.id)

############################################
# Empty Mapping File
############################################

echo "{}" > output/files.json

############################################
# Read Unique Files
############################################

FILES=$(jq -r '
if .violations then
    [.violations[].locations[0].file]
else
    [.runs[].violations[].locations[0].file]
end
| unique
| .[]
' output/sfca.json)

############################################
# Loop Files
############################################

for FILE in $FILES
do

FILE_NAME=$(basename "$FILE")

LANGUAGE="Apex"

if [[ "$FILE" == *.trigger ]]; then
    LANGUAGE="Trigger"
fi

RESULT=$(sf data create record \
--target-org "$TARGET_ORG" \
--sobject dx_Code_File__c \
--values "
Name=${FILE_NAME}
File_Name__c=${FILE_NAME}
File_Path__c=${FILE}
Language__c=${LANGUAGE}
File_Status__c=Active
Last_Scan__c=$(date +"%Y-%m-%dT%H:%M:%SZ")
Code_Analyzer__c=${ANALYZER_ID}
Total_Violations__c=0
Critical_Count__c=0
High_Count__c=0
Medium_Count__c=0
Low_Count__c=0
" \
--json)

FILE_ID=$(echo "$RESULT" | jq -r '.result.id')

############################################
# Store Mapping
############################################

jq \
--arg path "$FILE" \
--arg id "$FILE_ID" \
'. + {($path):$id}' \
output/files.json \
> output/tmp.json

mv output/tmp.json output/files.json

echo "$FILE_NAME uploaded"

done

banner "Files Upload Completed"
