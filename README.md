Sequel::Fixture
===============
[![Build Status](https://secure.travis-ci.org/Fetcher/sequel-fixture.png)](http://travis-ci.org/Fetcher/sequel-fixture) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/Fetcher/sequel-fixture)

Just like Rails fixtures, but for Sequel.

This  version includes support for defining the fixture schemas
and uses sqlite3 adapter to inject data into memory.

Usage
=====
Each fixture file defines the schema and data for a single table which
is named after the file name.

Schema definition is optional, but note that db inserts will fail if the tables do
not exist.

Assuming you have a fixture for the table users with:
```yaml
# fixtures/simple/users.yaml
schema:
  - name: name
    type: string
    primary_key: true
  - name: last_name
    type: string
  - name: empty
    type: string
data:
  - name: John
    last_name: Doe
    email: john@doe.com
  - name: Jane
    last_name: Doe
    email: jane@doe.com
```

and for messages:
```yaml
# fixtures/simple/messages.yaml
schema:
  - name: sender_id
    type: integer
    primary_key: true
  - name: receiver_id
    type: integer
  - name: text
    type: string
data:
  - sender_id: 1
    receiver_id: 2
    text: Hi Jane! Long time no see.
  - sender_id: 2
    receiver_id: 1
    text: John! Long time indeed. How are you doing?
```

and the ruby script

```ruby
# script.rb
require "sequel-fixture"

DB = Sequel.sqlite # Just a simple example, needs sqlite3 gem

## Set the path of the fixture yaml files to be [script.rb]/fixtures/
Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")

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

...naturally, `sequel-fixture` makes a lot more sense within some testing framework.


Contributing
------------

```
bundle install --binstubs .bin --path vendor/bundle
```

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
