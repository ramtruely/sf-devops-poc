@isTest
private class HelloWorldTest {

    @isTest
    static void testHelloWorld() {

        Profile p = [SELECT Id FROM Profile LIMIT 1];

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

            System.assertEquals(
                'Hello DevOps World!',
                result,
                'Unexpected greeting message'
            );
        }
    }
}