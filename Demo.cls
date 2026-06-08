---
name: SFCA Salesforce Loader

on:
  workflow_dispatch:

jobs:

  load-sfca:

    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      # ----------------------------------
      # Salesforce Authentication
      # ----------------------------------

      - name: Auth Salesforce
        id: sfdx-auth
        uses: allegis-is/allegis-sf-action/sf-authentication@master
        with:
          sfdx_alias: test-org

      # ----------------------------------
      # Verify Login
      # ----------------------------------

      - name: Verify Org
        run: |
          sf org list

      - name: Verify Org Details
        run: |
          sf org display --target-org test-org

      # ----------------------------------
      # Python Setup
      # ----------------------------------

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      # ----------------------------------
      # Execute Loader
      # ----------------------------------

      - name: Load JSON Into Salesforce
        run: |
          python scripts/load_sfca_to_salesforce.py


---
import json
import subprocess

print("Loading SFCA JSON")

with open("sfca_results.json", "r") as f:
    data = json.load(f)

run_dir = data["runDir"]

versions = data["versions"]

counts = data["violationCounts"]

# ------------------------------------------------
# Create Analyzer Record
# ------------------------------------------------

create_analyzer = f"""
sf data create record \
--sobject dx_Code_Analyzer__c \
--values "
Name='SFCA Run'
Author__c='GitHub'
Branch__c='feature-ram-sfca'
Commit_ID__c='POC'
Package__c='{run_dir}'
" \
--target-org test-org \
--json
"""

result = subprocess.check_output(
    create_analyzer,
    shell=True,
    text=True
)

analyzer = json.loads(result)

analyzer_id = analyzer["result"]["id"]

print(f"Analyzer Created: {analyzer_id}")

# ------------------------------------------------
# Create File + Violations
# ------------------------------------------------

file_map = {}

for violation in data["violations"]:

    for location in violation["locations"]:

        file_path = location["file"]

        if file_path not in file_map:

            create_file = f"""
            sf data create record \
            --sobject dx_Code_File__c \
            --values "
            Name='{file_path.split('/')[-1]}'
            File_Path__c='{file_path}'
            Language__c='Apex'
            File_Status__c='Scanned'
            Code_Analyzer__c='{analyzer_id}'
            " \
            --target-org test-org \
            --json
            """

            file_result = subprocess.check_output(
                create_file,
                shell=True,
                text=True
            )

            file_json = json.loads(file_result)

            file_id = file_json["result"]["id"]

            file_map[file_path] = file_id

            print(f"File Created: {file_path}")

        file_id = file_map[file_path]

        message = violation.get(
            "message",
            ""
        ).replace('"', "'")

        create_violation = f"""
        sf data create record \
        --sobject dx_Code_Violation__c \
        --values "
        Rule__c='{violation['rule']}'
        Engine__c='{violation['engine']}'
        Severity__c={violation['severity']}
        Message__c='{message}'
        Line_Number__c={location['startLine']}
        Status__c='Open'
        Code_File__c='{file_id}'
        " \
        --target-org test-org
        """

        subprocess.run(
            create_violation,
            shell=True,
            check=True
        )

print("Completed Successfully")
---

name: SFCA Salesforce Loader

on:
  workflow_dispatch:

jobs:

  load-sfca:

    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: |
          npm install -g @salesforce/cli

      - name: Authenticate Salesforce
        run: |
          echo "${{ secrets.SFDX_AUTH_URL }}" > auth.txt

          sf org login sfdx-url \
            --sfdx-url-file auth.txt \
            --alias test-org

      - name: Verify Login
        run: |
          sf org display --target-org test-org

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Execute Loader
        run: |
          python scripts/load_sfca_to_salesforce.py
