#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "Upload Pull Request"

login_sf

############################################
# Verify Analyzer Id
############################################

if [ ! -f output/analyzer.id ]; then
    log_error "Analyzer Id missing."
    exit 1
fi

ANALYZER_ID=$(cat output/analyzer.id)

############################################
# GitHub Details
############################################

REPOSITORY="${GITHUB_REPOSITORY:-dx-sample-test}"
AUTHOR="${GITHUB_ACTOR:-Unknown}"

SOURCE_BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME}}"
TARGET_BRANCH="${GITHUB_BASE_REF:-develop}"

PR_NUMBER="${PR_NUMBER:-0}"
PR_TITLE="${PR_TITLE:-GitHub Pull Request}"

STATUS="Open"
REVIEW_STATUS="Pending"

CREATED_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ")

############################################
# GitHub Event (Optional)
############################################

if [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then

    PR_NUMBER=$(jq -r '.pull_request.number // 0' "$GITHUB_EVENT_PATH")

    PR_TITLE=$(jq -r '.pull_request.title // "GitHub Pull Request"' "$GITHUB_EVENT_PATH")

    STATUS=$(jq -r '.pull_request.state // "Open"' "$GITHUB_EVENT_PATH")

    REVIEW_STATUS="Pending"

fi

############################################
# Create Pull Request Record
############################################

RESULT=$(sf data create record \
--target-org "$TARGET_ORG" \
--sobject DX_Pull_Request__c \
--values "
Name=PR_${PR_NUMBER}
Analyzer__c=${ANALYZER_ID}
Repository__c=${REPOSITORY}
PR_Number__c=${PR_NUMBER}
PR_Title__c=${PR_TITLE}
Author__c=${AUTHOR}
Source_Branch__c=${SOURCE_BRANCH}
Target_Branch__c=${TARGET_BRANCH}
Status__c=${STATUS}
Review_Status__c=${REVIEW_STATUS}
Created_Date__c=${CREATED_DATE}
" \
--json)

PR_ID=$(echo "$RESULT" | jq -r '.result.id')

if [ -z "$PR_ID" ] || [ "$PR_ID" = "null" ]; then
    log_error "Unable to create Pull Request record."
    echo "$RESULT"
    exit 1
fi

log_info "Pull Request Created : $PR_ID"

banner "Pull Request Upload Completed"
