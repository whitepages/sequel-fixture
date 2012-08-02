#Scenario: Create a simple fixture, push it into a sqlite and rollback
#  Given a table visitors with String:name, String:email
#  And a table aliens with String:race
#  And a table visits with Integer:alien_id, Integer:visitor_id
#  And a file "test/fixtures/simple/visitors.yaml" with:
#    """
#    anonymous:
#      name: V
#      email: v@for.vendetta
#    """
#  And a file "test/fixtures/simple/aliens.yaml" with:
#    """
#    yourfavouritemartian:
#      race: Zerg
#    """
#  And a file "test/fixtures/simple/visits.yaml" with:
#    """
#    v2yfm:
#      alien_id: 1
#      visitor_id: 1
#    """
#  When I load the simple fixture
#  Then I should see 1 record in visitors with name "V" and email "v@for.vendetta"
#  And I should see 1 record in aliens with race "Zerg"
#  And I should see 1 record in visits with alien_id 1 and visitor_id 1

Given /^a table (\w+) with (\w+):(\w+), (\w+):(\w+)$/ do |table, type1, field1, type2, field2|
  @DB.create_table table.to_sym do
    send :"#{type1}", field1
    send :"#{type2}", field2
  end
end

Given /^a table (\w+) with (\w+):(\w+)$/ do |table, type, field|
  @DB.create_table table.to_sym do
    send :"#{type}", field
  end
end

And /^a file "(.+?)" with:$/ do |path, content|
  Fast.file.write path, content
end

When /^I load the (\w+) fixture$/ do |fixture|
  @fixture = Sequel::Fixture.new fixture.to_sym, @DB
end

Then /^I should see (\d) record in (\w+) with (\w+) "(.+?)" and (\w+) "(.+?)"$/ do |amount, table, field1, data1, field2, data2|
  @DB[table.to_sym].where(field1.to_sym => data1, field2.to_sym => data2).count.should == amount.to_i
end

And /^I should see (\d) record in (\w+) with (\w+) "([^"]+)"$/ do |amount, table, field1, data1|
  @DB[table.to_sym].where(field1.to_sym => data1).count.should == amount.to_i
end

Then /^I should see (\d) record in (\w+) with (\w+) (\d+) and (\w+) (\d+)$/ do |amount, table, field1, data1, field2, data2|
  @DB[table.to_sym].where(field1.to_sym => data1.to_i, field2.to_sym => data2.to_i).count.should == amount.to_i
end

When /^I rollback$/ do
  @fixture.rollback
end
