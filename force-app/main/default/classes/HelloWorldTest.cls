@isTest
private class HelloWorldTest {

    @isTest
    static void testHelloWorld() {

        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            Alias = 'testusr',
            Email='testuser@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Test',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            Username='testuser' + System.currentTimeMillis() + '@test.com'
        );

        insert u;

        System.runAs(u) {
            String result = HelloWorld.sayHello();

            // ✅ Add assertion message
            System.assertEquals('Hello, World', result, 'Unexpected greeting message');
        }
    }
}