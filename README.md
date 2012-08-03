Sequel::Fixture
===============

Just like Rails 2 fixtures, but for Sequel.

Show off
========

Assuming you have a fixture for the table users with:
```yaml
# test/fixtures/simple/users.yaml
john:
  name: John
  last_name: Doe
  email: john@doe.com
jane:
  name: Jane
  last_name: Doe
  email: jane@doe.com
```

and for messages:
```yaml
# test/fixtures/simple/messages.yaml
greeting:
  sender_id: 1
  receiver_id: 2
  text: Hi Jane! Long time no see.
long_time:
  sender_id: 2
  receiver_id: 1
  text: John! Long time indeed. How are you doing?

```ruby
# script.rb
require "sequel-fixture"

DB = Sequel.sqlite # Just a simple example, needs sqlite3 gem

fixture = Sequel::Fixture.new :simple, DB # Will load all the data in the fixture into the database

fixture.users               # == fixture[:users]
fixture.users.john.name     # => "John"
                            # The YAML files are parsed into a SymbolMatrix
                            # http://github.com/Fetcher/symbolmatrix

fixture.rollback            # returns users and messages to pristine status ('TRUNCATE')


fixture = Sequel::Fixture.new :simple, DB, false    # The `false` flag prevent the constructor to automatically push
                                                    # the fixture into the database
                                                    
fixture.check               # Will fail if the user or messages table
                            # were already occupied with something
                            
fixture.push                # Inserts the fixture in the database

fixture.rollback            # Don't forget to rollback

```

> **Note**: As of version 0.0.1, the `test/fixtures` path for fixtures is not configurable. Will solve soon.

Installation
------------

    gem install sequel-fixture

### Or using Bundler

    gem 'sequel-fixture'

And then execute:

    bundle


## License

Copyright (C) 2012 Fetcher

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
