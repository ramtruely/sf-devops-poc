#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "Upload Analyzer"

login_sf

###############################################
# Verify Files
###############################################

if [ ! -f output/analyzer.json ]; then
    log_error "output/analyzer.json not found."
    exit 1
fi

###############################################
# Read Summary JSON
###############################################

REPOSITORY=$(jq -r '.repository' output/analyzer.json)
BRANCH=$(jq -r '.branch' output/analyzer.json)
COMMIT=$(jq -r '.commit' output/analyzer.json)
AUTHOR=$(jq -r '.author' output/analyzer.json)

TOTAL_FILES=$(jq -r '.totalFiles' output/analyzer.json)
TOTAL_VIOLATIONS=$(jq -r '.totalViolations' output/analyzer.json)

CRITICAL=$(jq -r '.critical' output/analyzer.json)
HIGH=$(jq -r '.high' output/analyzer.json)
MEDIUM=$(jq -r '.medium' output/analyzer.json)
LOW=$(jq -r '.low' output/analyzer.json)

QUALITY_GATE=$(jq -r '.qualityGate' output/analyzer.json)
COVERAGE=$(jq -r '.coverage' output/analyzer.json)

PACKAGE="${PACKAGE_NAME:-dx-sample-test}"

PUSH_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ")

###############################################
# Create Analyzer
###############################################

log_info "Creating dx_Code_Analyzer__c"

RESULT=$(sf data create record \
    --target-org "${TARGET_ORG}" \
    --sobject dx_Code_Analyzer__c \
    --values "
Name=SFCA_${GITHUB_RUN_NUMBER:-1}
Repository__c=${REPOSITORY}
Package__c=${PACKAGE}
Branch__c=${BRANCH}
Commit_ID__c=${COMMIT}
Author__c=${AUTHOR}
Pushed_Date__c=${PUSH_DATE}
Coverage__c=${COVERAGE}
Total_Files__c=${TOTAL_FILES}
Total_Violations__c=${TOTAL_VIOLATIONS}
Critical_Count__c=${CRITICAL}
High_Count__c=${HIGH}
Medium_Count__c=${MEDIUM}
Low_Count__c=${LOW}
Quality_Gate__c=${QUALITY_GATE}
Analysis_Duration__c=0
" \
--json)

###############################################
# Extract Salesforce Id
###############################################

ANALYZER_ID=$(echo "$RESULT" | jq -r '.result.id')

if [ -z "$ANALYZER_ID" ] || [ "$ANALYZER_ID" = "null" ]; then
    log_error "Unable to create Analyzer."
    echo "$RESULT"
    exit 1
fi

###############################################
# Store Analyzer Id
###############################################

echo "$ANALYZER_ID" > output/analyzer.id

log_info "Analyzer Created"

log_info "$ANALYZER_ID"

banner "Analyzer Upload Completed"
