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
