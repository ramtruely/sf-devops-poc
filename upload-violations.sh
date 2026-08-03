#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "Upload Violations"

login_sf

############################################
# Verify Inputs
############################################

[ -f output/analyzer.json ] || { log_error "Missing analyzer.json"; exit 1; }
[ -f output/files.json ] || { log_error "Missing files.json"; exit 1; }
[ -f output/sfca.json ] || { log_error "Missing sfca.json"; exit 1; }

REPOSITORY=$(jq -r '.repository' output/analyzer.json)
BRANCH=$(jq -r '.branch' output/analyzer.json)
COMMIT=$(jq -r '.commit' output/analyzer.json)
AUTHOR=$(jq -r '.author' output/analyzer.json)

############################################
# Parse Violations
############################################

jq -c '
if .violations then
    .violations[]
else
    .runs[].violations[]
end
' output/sfca.json | while read -r V
do

    FILE=$(echo "$V" | jq -r '.locations[0].file')

    FILE_ID=$(jq -r --arg f "$FILE" '.[$f]' output/files.json)

    RULE=$(echo "$V" | jq -r '.rule')
    ENGINE=$(echo "$V" | jq -r '.engine')

    MESSAGE=$(echo "$V" | jq -r '.message')

    SEVERITY=$(echo "$V" | jq -r '.severity')

    START_LINE=$(echo "$V" | jq -r '.locations[0].startLine // 0')
    END_LINE=$(echo "$V" | jq -r '.locations[0].endLine // 0')

    START_COLUMN=$(echo "$V" | jq -r '.locations[0].startColumn // 0')
    END_COLUMN=$(echo "$V" | jq -r '.locations[0].endColumn // 0')

    TAGS=$(echo "$V" | jq -r '.tags|join(";") // ""')

    ISSUE_TYPE=$(echo "$V" | jq -r '.type // ""')

    UUID=$(uuidgen)

    ########################################

    sf data create record \
    --target-org "$TARGET_ORG" \
    --sobject dx_Code_Violation__c \
    --values "
Name=${RULE}
Repository__c=${REPOSITORY}
Branch__c=${BRANCH}
Commit_ID__c=${COMMIT}
Code_File__c=${FILE_ID}
Violation_ID__c=${UUID}
Rule__c=${RULE}
Engine__c=${ENGINE}
Severity__c=${SEVERITY}
Issue_Type__c=${ISSUE_TYPE}
Message__c=${MESSAGE}
Status__c=Open
Resolution__c=
Tags__c=${TAGS}
Start_Line__c=${START_LINE}
End_Line__c=${END_LINE}
Start_Column__c=${START_COLUMN}
End_Column__c=${END_COLUMN}
Author__c=${AUTHOR}
Created_Date__c=$(date +"%Y-%m-%dT%H:%M:%SZ")
"

    ########################################
    # Update File Counters
    ########################################

    case "$SEVERITY" in
        1)
            FIELD="Critical_Count__c"
            ;;
        2)
            FIELD="High_Count__c"
            ;;
        3)
            FIELD="Medium_Count__c"
            ;;
        *)
            FIELD="Low_Count__c"
            ;;
    esac

    sf data update record \
        --target-org "$TARGET_ORG" \
        --sobject dx_Code_File__c \
        --record-id "$FILE_ID" \
        --values "
Total_Violations__c+=1
${FIELD}+=1
" >/dev/null 2>&1 || true

done

banner "Violations Uploaded"
