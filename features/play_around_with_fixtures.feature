Feature: Play around with Fixtures
  In order to test if Sequel::Fixture is really practical
  As the gem developer
  I want to play around with it a little bit

Background: We have a database connection working
  Given a sqlite database connection

Scenario: Create a simple fixture, push it into a sqlite and rollback
  Given a table visitors with String:name, String:email
  And a table aliens with String:race
  And a table visits with Integer:alien_id, Integer:visitor_id
  And a file "test/fixtures/simple/visitors.yaml" with:
    """
    anonymous:
      name: V
      email: v@for.vendetta
    """
  And a file "test/fixtures/simple/aliens.yaml" with:
    """
    yourfavouritemartian:
      race: Zerg
    """
  And a file "test/fixtures/simple/visits.yaml" with:
    """
    v2yfm:
      alien_id: 1
      visitor_id: 1
    """
  When I load the simple fixture
  Then I should see 1 record in visitors with name "V" and email "v@for.vendetta"
  And I should see 1 record in aliens with race "Zerg"
  And I should see 1 record in visits with alien_id 1 and visitor_id 1
  When I rollback
  Then I should see 0 records in visitors
  And I should see 0 records in aliens
  And I should see 0 records in visits

#Scenario: The users table has a password field
#  Given a table users with String:name, String:password
#  And a file "test/fixtures/password/users.yaml" with: 
#    """
#    john:
#      name: John Wayne
#      password:
#        raw: secret
#        processed: 5bfb52c459cdb07218c176b5ddec9b6215bd5b76
#    """
#  When I load the password fixture
#  Then I should see 1 record in users with name "John Wayne" and password "5bfb52c459cdb07218c176b5ddec9b6215bd5b76"    
