#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "Upload Repository Trend"

login_sf

############################################
# Verify Required Files
############################################

[ -f output/analyzer.id ] || {
    log_error "Analyzer Id missing."
    exit 1
}

[ -f output/analyzer.json ] || {
    log_error "Analyzer JSON missing."
    exit 1
}

############################################
# Read Analyzer Id
############################################

ANALYZER_ID=$(cat output/analyzer.id)

############################################
# Read Analyzer Summary
############################################

REPOSITORY=$(jq -r '.repository' output/analyzer.json)
BRANCH=$(jq -r '.branch' output/analyzer.json)

COVERAGE=$(jq -r '.coverage' output/analyzer.json)

TOTAL=$(jq -r '.totalViolations' output/analyzer.json)

CRITICAL=$(jq -r '.critical' output/analyzer.json)
HIGH=$(jq -r '.high' output/analyzer.json)
MEDIUM=$(jq -r '.medium' output/analyzer.json)
LOW=$(jq -r '.low' output/analyzer.json)
INFO=$(jq -r '.info' output/analyzer.json)

############################################
# Calculate Health Score
############################################

HEALTH=100

HEALTH=$((HEALTH-(CRITICAL*20)))
HEALTH=$((HEALTH-(HIGH*10)))
HEALTH=$((HEALTH-(MEDIUM*5)))
HEALTH=$((HEALTH-(LOW*2)))
HEALTH=$((HEALTH-(INFO)))

if [ "$HEALTH" -lt 0 ]; then
    HEALTH=0
fi

############################################
# Analysis Date
############################################

ANALYSIS_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ")

############################################
# Create Trend Record
############################################

RESULT=$(sf data create record \
--target-org "$TARGET_ORG" \
--sobject DX_Repository_Trend__c \
--values "
Name=Trend_${GITHUB_RUN_NUMBER:-1}
dx_Code_Analyzer__c=${ANALYZER_ID}
Repository__c=${REPOSITORY}
Branch__c=${BRANCH}
Analysis_Date__c=${ANALYSIS_DATE}
Coverage__c=${COVERAGE}
Health_Score__c=${HEALTH}
Critical__c=${CRITICAL}
High__c=${HIGH}
Medium__c=${MEDIUM}
Low__c=${LOW}
Info__c=${INFO}
Total_Violations__c=${TOTAL}
" \
--json)

TREND_ID=$(echo "$RESULT" | jq -r '.result.id')

if [ -z "$TREND_ID" ] || [ "$TREND_ID" = "null" ]; then
    log_error "Repository Trend creation failed."
    echo "$RESULT"
    exit 1
fi

log_info "Repository Trend Created"

log_info "$TREND_ID"

banner "Repository Trend Upload Completed"
