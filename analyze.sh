#!/bin/bash

set -euo pipefail

source scripts/common.sh

banner "DX Visualizer Analysis"

verify_output

###############################################
# Configuration
###############################################

SFCA_FILE="${SFCA_FILE:-output/sfca.json}"

if [ ! -f "$SFCA_FILE" ]; then
    log_error "SFCA JSON not found : $SFCA_FILE"
    exit 1
fi

###############################################
# Git Information
###############################################

REPOSITORY="${GITHUB_REPOSITORY:-dx-sample-test}"
BRANCH="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD)}"
AUTHOR="${GITHUB_ACTOR:-unknown}"

###############################################
# Metadata Counts
###############################################

TOTAL_FILES=$(find force-app -type f | wc -l | tr -d ' ')

APEX_CLASSES=$(find force-app -name "*.cls" | wc -l | tr -d ' ')

TRIGGERS=$(find force-app -name "*.trigger" | wc -l | tr -d ' ')

LWC=$(find force-app/main/default/lwc \
-type d \
-mindepth 1 \
-maxdepth 1 2>/dev/null | wc -l | tr -d ' ')

OBJECTS=$(find force-app/main/default/objects \
-type d \
-mindepth 1 \
-maxdepth 1 2>/dev/null | wc -l | tr -d ' ')

FLOWS=$(find force-app -name "*.flow-meta.xml" | wc -l | tr -d ' ')

###############################################
# Violation Counts
###############################################

TOTAL_VIOLATIONS=$(jq '.violations | length' "$SFCA_FILE")

CRITICAL=$(jq '[.violations[] | select(.severity==1)] | length' "$SFCA_FILE")

HIGH=$(jq '[.violations[] | select(.severity==2)] | length' "$SFCA_FILE")

MEDIUM=$(jq '[.violations[] | select(.severity==3)] | length' "$SFCA_FILE")

LOW=$(jq '[.violations[] | select(.severity==4)] | length' "$SFCA_FILE")

INFO=$(jq '[.violations[] | select(.severity==5)] | length' "$SFCA_FILE")

###############################################
# Coverage
###############################################

COVERAGE=0

###############################################
# Quality Gate
###############################################

QUALITY_GATE="PASS"

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
    QUALITY_GATE="FAIL"
fi

###############################################
# Build Analyzer JSON
###############################################

jq -n \
--arg repo "$REPOSITORY" \
--arg branch "$BRANCH" \
--arg commit "$COMMIT" \
--arg author "$AUTHOR" \
--arg gate "$QUALITY_GATE" \
--argjson files "$TOTAL_FILES" \
--argjson classes "$APEX_CLASSES" \
--argjson triggers "$TRIGGERS" \
--argjson lwc "$LWC" \
--argjson objects "$OBJECTS" \
--argjson flows "$FLOWS" \
--argjson total "$TOTAL_VIOLATIONS" \
--argjson critical "$CRITICAL" \
--argjson high "$HIGH" \
--argjson medium "$MEDIUM" \
--argjson low "$LOW" \
--argjson info "$INFO" \
--argjson coverage "$COVERAGE" \
'{
repository:$repo,
branch:$branch,
commit:$commit,
author:$author,
qualityGate:$gate,
coverage:$coverage,
totalFiles:$files,
apexClasses:$classes,
triggers:$triggers,
lwc:$lwc,
objects:$objects,
flows:$flows,
totalViolations:$total,
critical:$critical,
high:$high,
medium:$medium,
low:$low,
info:$info
}' > output/analyzer.json

###############################################
# Summary
###############################################

log_info "Repository : $REPOSITORY"
log_info "Branch     : $BRANCH"
log_info "Files      : $TOTAL_FILES"
log_info "Violations : $TOTAL_VIOLATIONS"
log_info "Quality    : $QUALITY_GATE"

banner "Analysis Completed"
