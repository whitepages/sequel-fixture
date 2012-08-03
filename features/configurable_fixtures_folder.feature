Feature: Configurable fixtures folder
  In order to load fixtures from arbitrary folders
  I want to be able to configure the source of the fixtures

Background: We have a database connection working
  Given a sqlite database connection
  
Scenario: The folder is now just "fixtures"
  Given a table users with String:name, String:email
  And a file "fixtures/configurable/users.yaml" with:
    """
    xavi:
      name: Xavier
      email: xavier@via.com
    john:
      name: Johnny
      email: john@doe.com
    """
  When I set the fixtures path as "fixtures"
  And I load the configurable fixture
  Then I should see 1 record in users with name "Xavier" and email "xavier@via.com"
  And I should see 1 record in users with name "Johnny" and email "john@doe.com"
  When I rollback
  Then I should see 0 records in users
