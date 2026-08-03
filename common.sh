#!/bin/bash

set -euo pipefail

###############################################
# Configuration
###############################################

TARGET_ORG="${TARGET_ORG:-dxvizdev}"
OUTPUT_DIR="output"

mkdir -p "${OUTPUT_DIR}"

###############################################
# Logging
###############################################

log_info() {
    echo "[INFO ] $1"
}

log_warn() {
    echo "[WARN ] $1"
}

log_error() {
    echo "[ERROR] $1"
}

###############################################
# Execute Command
###############################################

run() {
    log_info "$1"
    eval "$1"
}

###############################################
# Salesforce Login
###############################################

login_sf() {

    log_info "Authenticating Salesforce Org..."

    if sf org list --json | jq -e ".result.nonScratchOrgs[] | select(.alias==\"${TARGET_ORG}\")" >/dev/null; then
        log_info "Already authenticated."
        return
    fi

    if [ -z "${SF_AUTH_URL:-}" ]; then
        log_error "SF_AUTH_URL environment variable not found."
        exit 1
    fi

    echo "${SF_AUTH_URL}" > auth.txt

    sf org login sfdx-url \
        --sfdx-url-file auth.txt \
        --alias "${TARGET_ORG}" \
        --set-default

    rm -f auth.txt
}

###############################################
# Execute SOQL
###############################################

query() {

    local soql="$1"

    sf data query \
        --target-org "${TARGET_ORG}" \
        --query "${soql}" \
        --json
}

###############################################
# Create Salesforce Record
###############################################

create_record() {

    local object="$1"
    local values="$2"

    sf data create record \
        --target-org "${TARGET_ORG}" \
        --sobject "${object}" \
        --values "${values}" \
        --json
}

###############################################
# Save Variable
###############################################

save_value() {

    local file="$1"
    local value="$2"

    echo "${value}" > "${OUTPUT_DIR}/${file}"
}

###############################################
# Read Variable
###############################################

read_value() {

    local file="$1"

    cat "${OUTPUT_DIR}/${file}"
}

###############################################
# Verify Output Folder
###############################################

verify_output() {

    if [ ! -d "${OUTPUT_DIR}" ]; then
        mkdir -p "${OUTPUT_DIR}"
    fi
}

###############################################
# Start Banner
###############################################

banner() {

echo "=================================================="
echo "$1"
echo "=================================================="

}
