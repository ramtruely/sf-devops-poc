#!/bin/bash

set -euo pipefail

###########################################################
# Common Utilities
###########################################################

TARGET_ORG="${TARGET_ORG:-CLMDEV}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

mkdir -p "${OUTPUT_DIR}"

###########################################################
# Logging
###########################################################

log_info() {
    echo "[INFO ] $*"
}

log_warn() {
    echo "[WARN ] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

###########################################################
# Banner
###########################################################

banner() {

echo
echo "=========================================================="
echo " $1"
echo "=========================================================="
echo

}

###########################################################
# Verify Output Folder
###########################################################

verify_output() {

mkdir -p "${OUTPUT_DIR}"

}

###########################################################
# Salesforce Login
###########################################################

login_sf() {

log_info "Checking Salesforce authentication..."

if sf org list --json | \
jq -e ".result.nonScratchOrgs[] | select(.alias==\"${TARGET_ORG}\")" >/dev/null 2>&1
then
    log_info "Already authenticated : ${TARGET_ORG}"
    return
fi

if [ -z "${SFDX_AUTH_URL:-}" ]; then
    log_error "Environment variable SFDX_AUTH_URL is missing."
    exit 1
fi

echo "${SFDX_AUTH_URL}" > auth.txt

sf org login sfdx-url \
    --sfdx-url-file auth.txt \
    --alias "${TARGET_ORG}" \
    --set-default

rm -f auth.txt

log_info "Salesforce login successful."

}

###########################################################
# Generic SOQL Query
###########################################################

query() {

local SOQL="$1"

sf data query \
    --target-org "${TARGET_ORG}" \
    --query "${SOQL}" \
    --json

}

###########################################################
# Create Record
###########################################################

create_record() {

local OBJECT="$1"
local VALUES="$2"

sf data create record \
    --target-org "${TARGET_ORG}" \
    --sobject "${OBJECT}" \
    --values "${VALUES}" \
    --json

}

###########################################################
# Update Record
###########################################################

update_record() {

local OBJECT="$1"
local ID="$2"
local VALUES="$3"

sf data update record \
    --target-org "${TARGET_ORG}" \
    --sobject "${OBJECT}" \
    --record-id "${ID}" \
    --values "${VALUES}" \
    --json

}

###########################################################
# Delete Record
###########################################################

delete_record() {

local OBJECT="$1"
local ID="$2"

sf data delete record \
    --target-org "${TARGET_ORG}" \
    --sobject "${OBJECT}" \
    --record-id "${ID}"

}

###########################################################
# Save Helper
###########################################################

save_value() {

echo "$2" > "${OUTPUT_DIR}/$1"

}

###########################################################
# Read Helper
###########################################################

read_value() {

cat "${OUTPUT_DIR}/$1"

}

###########################################################
# Execute Command
###########################################################

run() {

log_info "$*"

"$@"

}

###########################################################
# Cleanup
###########################################################

cleanup() {

rm -f auth.txt

find "${OUTPUT_DIR}" \
-type f \
-name "*.tmp" \
-delete

}

###########################################################
# Exit Handler
###########################################################

trap cleanup EXIT
