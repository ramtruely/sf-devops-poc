---
import json
import subprocess

with open("sfca_results.json") as f:
    data = json.load(f)

run_dir = data["runDir"]

versions = data["versions"]

counts = data["violationCounts"]

#################################################
# CREATE SCAN RUN
#################################################

cmd = f'''
sf data create record \
--sobject Scan_Run__c \
--values "
Run_Dir__c={run_dir}
Analyzer_Version__c={versions['code-analyzer']}
Regex_Version__c={versions['regex']}
PMD_Version__c={versions['pmd']}
Total_Violations__c={counts['total']}
SEV1_Count__c={counts['sev1']}
SEV2_Count__c={counts['sev2']}
SEV3_Count__c={counts['sev3']}
SEV4_Count__c={counts['sev4']}
SEV5_Count__c={counts['sev5']}
" \
--target-org test-org \
--json
'''

result = subprocess.check_output(cmd, shell=True)

response = json.loads(result)

scan_run_id = response["result"]["id"]

print(f"Scan Run Created: {scan_run_id}")

#################################################
# CREATE VIOLATIONS
#################################################

for violation in data["violations"]:

    tags = ",".join(violation.get("tags", []))

    resources = ",".join(
        violation.get("resources", [])
    )

    message = violation.get("message", "")

    cmd = f'''
    sf data create record \
    --sobject Scan_Violation__c \
    --values "
    Scan_Run__c={scan_run_id}
    Rule__c={violation['rule']}
    Engine__c={violation['engine']}
    Severity__c={violation['severity']}
    Primary_Location_Index__c={violation['primaryLocationIndex']}
    Message__c={message}
    Tags__c={tags}
    Resources__c={resources}
    " \
    --target-org test-org \
    --json
    '''

    result = subprocess.check_output(
        cmd,
        shell=True
    )

    response = json.loads(result)

    violation_id = response["result"]["id"]

    print(
        f"Violation Created: {violation_id}"
    )

    #################################################
    # LOCATIONS
    #################################################

    for loc in violation["locations"]:

        cmd = f'''
        sf data create record \
        --sobject Violation_Location__c \
        --values "
        Scan_Violation__c={violation_id}
        File_Path__c={loc['file']}
        Start_Line__c={loc['startLine']}
        Start_Column__c={loc['startColumn']}
        End_Line__c={loc['endLine']}
        End_Column__c={loc['endColumn']}
        " \
        --target-org test-org
        '''

        subprocess.run(
            cmd,
            shell=True,
            check=True
        )

print("Completed")
---

name: SFCA Scan

on:
  push:
    branches:
      - feature-ram-sfca

jobs:
  sfca-scan:

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Install Salesforce Code Analyzer
        run: sf plugins install code-analyzer

      - name: Run SFCA
        run: |
          sf code-analyzer run \
          --workspace force-app \
          --output-file sfca_results.json

      - name: Authenticate Salesforce
        run: |
          echo "${{ secrets.SFDX_AUTH_URL }}" > auth.txt

          sf org login sfdx-url \
            --sfdx-url-file auth.txt \
            --alias test-org

      - name: Install Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Load Results Into Salesforce
        run: |
          python scripts/load_sfca_results.py

--
