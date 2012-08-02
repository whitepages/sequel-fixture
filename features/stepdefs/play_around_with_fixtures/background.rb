# Background: We have a database connection working
#   Given a sqlite database connection
Given /^a sqlite database connection$/ do
  @DB = Sequel.sqlite
end 
