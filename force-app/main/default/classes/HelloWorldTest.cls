@isTest
private class HelloWorldTest {
  @isTest
  static void testHello() {
    Test.startTest();

    String result = HelloWorld.sayHello();

    Test.stopTest();

    System.assertEquals('Hello DevOps World!', result);
  }
}
