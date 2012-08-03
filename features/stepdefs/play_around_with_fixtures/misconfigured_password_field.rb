#Scenario: Misconfigured password field
#  Given a table users with String:password
#  And a file "test/fixtures/misconfigured/users.yaml" with:
#    """
#    good_entry:
#      password:
#        raw: secret
#        processed: 96bdg756n5sgf9gfs==
#    wrong_entry:
#      password:
#        missing: The field
#    """
#  Then the loading of misconfigured fixture should fail
#  And I should see that the table was "users"
#  And I should see that the field was "password"
#  And I should see that the entry was "wrong_entry"
#  And I should see 0 records in users

# NOTE: most steps have been defined in 
# `create_a_simple_fixture_push_it_and_rollback.rb`

Then /^the loading of (\w+) fixture should fail$/ do |fixture|
  begin
    Sequel::Fixture.new fixture.to_sym, @DB
  rescue Sequel::Fixture::MissingProcessedValueError => e
    @exception = e
  end
end

And /^I should see that the table was "(\w+)"$/ do |table|
  @exception.message.should include table
end

And /^I should see that the field was "(\w+)"$/ do |field|
  @exception.message.should include field
end

And /^I should see that the entry was "(\w+)"$/ do |entry|
  @exception.message.should include entry
end
