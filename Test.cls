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
