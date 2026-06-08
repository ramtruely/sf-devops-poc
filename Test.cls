- name: Create Analyzer Record
  run: |
    sf data create record \
      --sobject dx_Code_Analyzer__c \
      --values "Name='SFCA POC Run',Author__c='Tulasiram',Branch__c='feature-ram-sfca',Commit_ID__c='12345',Package__c='Salesforce-sfca-poc'"
      --target-org test-org

---
name: Salesforce Test

on:
  workflow_dispatch:

jobs:
  test-login:
    runs-on: ubuntu-latest

    steps:

      - uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: npm install -g @salesforce/cli

      - name: Authenticate Org
        run: |
          echo "${{ secrets.SF_AUTH_URL }}" > auth.txt

          sf org login sfdx-url \
            --sfdx-url-file auth.txt \
            --alias test-org

      - name: Verify Login
        run: |
          sf org display --target-org test-org

---
name: SFCA POC

on:
  workflow_dispatch:

jobs:

  sfca-scan:

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: |
          npm install --global @salesforce/cli

      - name: Install Code Analyzer
        run: |
          echo y | sf plugins install code-analyzer

      - name: Verify Plugin
        run: |
          sf plugins

      - name: Run SFCA
        run: |
          sf code-analyzer run \
            --target force-app \
            --output-file sfca_results.json

      - name: Display Results
        run: |
          cat sfca_results.json

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: sfca-results
          path: sfca_results.json


---
public with sharing class AccountService {

    public static Account createAccount(String name) {

        Account acc = new Account();
        acc.Name = name;

        insert acc;

        return acc;
    }
}
----
@isTest
private class AccountServiceTest {

    @isTest
    static void testCreateAccount() {

        Test.startTest();

        Account acc = AccountService.createAccount('SFCA Test Account');

        Test.stopTest();

        System.assertNotEquals(null, acc.Id);
        System.assertEquals('SFCA Test Account', acc.Name);
    }
}

----
public class AccountUtility {

    public static void processAccounts() {

        List<Account> accs = [SELECT Id, Name FROM Account];

        for(Account a : accs) {
            System.debug(a.Name);
        }
    }
}
