require "sequel-fixture"
require "fast"

describe Sequel::Fixture do
  describe ".path" do
    it "returns 'test/fixtures'" do
      expect(Sequel::Fixture.path).to eq "test/fixtures"
    end

    it "is configurable" do
      Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      expect(Sequel::Fixture.path).to eq File.join(File.dirname(__FILE__), "fixtures")
    end
  end

  describe ".new" do
    context "a symbol is sent representing a fixture" do
      it "calls load_fixture" do
        expect_any_instance_of(Sequel::Fixture).to receive(:load).with :test
        Sequel::Fixture.new :test
      end
    end

    context "a database connection is passed" do
      it "calls push" do
        allow(Sequel).to receive(:connect).and_return Sequel::Database.new
        allow_any_instance_of(Sequel::Fixture).to receive :load
        expect_any_instance_of(Sequel::Fixture).to receive :push
        Sequel::Fixture.new :test, Sequel.connect
      end
    end

    context "a database is provided but no fixture" do
      it "does not call push" do
        database = double 'database'
        expect_any_instance_of(Sequel::Fixture).to_not receive :push
        Sequel::Fixture.new nil, database
      end
    end

    context "a database connection and a valid fixture are passed but a false flag is passed at the end" do
      it "does not push" do
        database = double 'database'
        allow_any_instance_of(Sequel::Fixture).to receive :load
        expect_any_instance_of(Sequel::Fixture).to_not receive :push
        Sequel::Fixture.new :test, database, false
      end
    end
  end

  describe "#load" do
    context "there is a valid fixture folder setup" do
      before do
        Sequel::Fixture.path = "test/fixtures"
        Fast.file! "test/fixtures/test/users.yaml"
        Fast.file! "test/fixtures/test/actions.yaml"
      end

      it "loads the fixture YAML files using SymbolMatrix (third-party)" do
        fix = Sequel::Fixture.new
        allow(fix).to receive :check
        expect(SymbolMatrix).to receive(:new).with "test/fixtures/test/users.yaml"
        expect(SymbolMatrix).to receive(:new).with "test/fixtures/test/actions.yaml"
        fix.load :test
      end

      after do
        Fast.dir.remove! :test
      end
    end

    context "the check has been performed and I attempt to load another fixture" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      end

      it "fails" do
        allow_any_instance_of(Sequel::Fixture).to receive :push
        database = double 'database'
        allow(database).to receive(:[]).and_return double(:count => 0 )
        fix = Sequel::Fixture.new :test, database
        fix.check
        expect { fix.load :another
        }.to raise_error Sequel::Fixture::LoadingFixtureIllegal,
          "A check has already been made, loading a different fixture is illegal"
      end

      after do
        Fast.dir.remove! :test
      end
    end
  end

  describe "#force_checked!" do
    it "check returns true and does not call [] in the passed database" do
      database = double 'database'
      expect(database).to_not receive :[]

      allow_any_instance_of(Sequel::Fixture).to receive :load
      fix = Sequel::Fixture.new :anything, database, false
      expect(fix.force_checked!).to eq true
      expect(fix.check).to be_truthy
    end
  end

  describe "#[]" do
    context "a valid fixture has been loaded" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")

        @fix = Sequel::Fixture.new
        allow(@fix).to receive :check
        @fix.load :test
      end

      context "a table key is passed" do
        it "returns the Fixture::Table containing the same info as in the matching YAML file" do
          expect(@fix[:users]).to be_a Sequel::Fixture::Table
          expect(@fix[:users][0].name).to eq "John Doe"
          expect(@fix[:users][0].last_name).to eq "Wayne"
          expect(@fix[:actions][0].action).to eq "Walks"
        end
      end

      after do
        Fast.dir.remove! :test
      end
    end
  end

  describe "#method_missing" do
    context "a valid fixture has been loaded" do
      context "a table key is passed" do
        before do
          Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
          @fix = Sequel::Fixture.new
          allow(@fix).to receive :check
          @fix.load :test
        end

        it "returns the SymbolMatrix containing the same info as in the matching YAML file" do
          expect(@fix.users).to be_a Sequel::Fixture::Table
          expect(@fix.users[0].name).to eq "John Doe"
          expect(@fix.users[0].last_name).to eq "Wayne"
          expect(@fix.actions[0].action).to eq "Walks"
        end

        after do
          Fast.dir.remove! :test
        end
      end
    end

    it "raises no method error if matches nothing" do
      expect { Sequel::Fixture.new.nothing = "hola"
      }.to raise_error NoMethodError
    end
  end

  describe "#fixtures_path" do
    it "calls Sequel::Fixture.path" do
      expect(Sequel::Fixture).to receive :path
      Sequel::Fixture.new.fixtures_path
    end
  end

  describe "#check" do

    context "the check has been done and it passed before" do
      it "returns true even if now tables don't pass" do
        allow_any_instance_of(Sequel::Fixture).to receive :push

        @counter = double 'counter'
        allow(@counter).to receive :count do
          @amount ||= 0
          @amount += 1
          0 unless @amount > 5
        end

        @database = double 'database'
        allow(@database).to receive(:[]).and_return @counter

        @fix = Sequel::Fixture.new nil, @database
        def @fix.stub_data
          @data = { :users => nil, :tables => nil, :actions => nil, :schemas => nil }
        end
        @fix.stub_data
        expect(@fix.check).to be_truthy
        expect(@fix.check).to be_truthy # This looks confusing: let's explain. The #count method as defined for the mock
                                        # runs 4 times in the first check. In the second check, it runs 4 times again.
                                        # After time 6 it returns a large amount, making the check fail.
                                        # Of course, the fourth time is never reached since the second check is skipped
      end
    end

    context "no fixture has been loaded" do
      it "fails with a missing fixture exception" do
        fix = Sequel::Fixture.new
        expect { fix.check
        }.to raise_error Sequel::Fixture::MissingFixtureError,
          "No fixture has been loaded, nothing to check"
      end
    end

    context "a valid fixture has been loaded but no connection has been provided" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Jane Doe }"
      end
      it "fails with a missing database connection exception" do
        fix = Sequel::Fixture.new :test
        expect { fix.check
        }.to raise_error Sequel::Fixture::MissingConnectionError,
          "No connection has been provided, impossible to check"
      end

      after do
        Fast.dir.remove! :test
      end
    end

    context "a database is provided but no fixture" do
      it "fails with a missing fixture exception" do
        database = double 'database'
        fix = Sequel::Fixture.new nil, database
        expect {fix.check
        }.to raise_error Sequel::Fixture::MissingFixtureError,
          "No fixture has been loaded, nothing to check"
      end
    end
  end

  describe "#connection" do
    it "returns the Sequel connection passed as argument to the constructor" do
      allow_any_instance_of(Sequel::Fixture).to receive :push
      connection = double
      fix = Sequel::Fixture.new nil, connection
      expect(fix.connection).to eq connection
    end
  end

  describe "#connection=" do
    it "sets the connection" do
      fix = Sequel::Fixture.new
      connection = double
      fix.connection = connection
      expect(fix.connection).to eq connection
    end

    context "a check has been performed and I attempt to change the connection" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Secret }"
      end

      it "fails" do
        database = double 'database'
        allow(database).to receive(:[]).and_return double(:count => 0)
        allow_any_instance_of(Sequel::Fixture).to receive :push
        fix = Sequel::Fixture.new :test, database
        fix.check
        expect { fix.connection = double 'database'
        }.to raise_error Sequel::Fixture::ChangingConnectionIllegal,
          "Illegal to change connection after check has already been performed"
      end

      after do
        Fast.dir.remove! :test
      end
    end
  end

  describe "#data" do
    context "a fixture has been loaded" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      end

      it "returns the fixture data" do
        fix = Sequel::Fixture.new :test
        expect(fix.data).to have_key :users
        expect(fix.data[:users]).to be_a Sequel::Fixture::Table
      end

      after do
        Fast.dir.remove! :test
      end
    end

    context "no fixture has been loaded" do
      it "returns nil" do
        fix = Sequel::Fixture.new
        expect(fix.data).to be {}
      end
    end
  end

  describe "#push" do
    it "calls #check" do
      fix = Sequel::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      expect(fix).to receive :check
      fix.push
    end

    context "a valid fixture and a database connection are provided" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")

        @table    = double
        @database = double :[] => @table
        @fix = Sequel::Fixture.new
        @fix.load :test
        @fix.connection = @database
      end

      it "attempts to insert the data into the database" do
        allow(@table).to receive(:count).and_return(0)
        expect(@table).to receive(:insert).with "name" => "John Doe", "last_name" => "Wayne"
        expect(@table).to receive(:insert).with "user_id" => 1, "action" => "Walks"
        @fix.push
      end

      after do
        Fast.dir.remove! :test
      end
    end

    context "a fixture with a field with a <raw> and a <processed> alternative" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      end

      it "inserts the <processed> alternative" do
        database = double 'database'
        insertable = double 'table'
        allow(insertable).to receive(:count).and_return(0)
        expect(insertable).to receive(:insert).with "password" => '35ferwt352'
        allow(database).to receive(:[]).and_return insertable

        fix = Sequel::Fixture.new :processed, database, false

        fix.push
      end

      after do
        Fast.dir.remove! :test
      end
    end

    context "a fixture with a field with alternatives yet missing the <processed> one" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      end

      it "fails" do
        database = double 'database', :[] => double( 'table', :count => 0, :truncate => nil  )
        fix = Sequel::Fixture.new :invalid, database, false

        expect { fix.push }.to raise_error Sequel::Fixture::MissingProcessedValueError
      end


      it "calls the rollback" do
        database = double 'database', :[] => double( 'table', :count => 0, :truncate => nil )
        fix = Sequel::Fixture.new :invalid, database, false
        expect(fix).to receive :rollback
        expect { fix.push }.to raise_error Sequel::Fixture::MissingProcessedValueError
      end

      after do
        Fast.dir.remove! :test
      end
    end
  end


  describe "#rollback" do
    it "checks" do
      fix = Sequel::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      expect(fix).to receive :check
      fix.rollback
    end

    context "the check is failing" do
      it "raises a custom error for the rollback" do
        fix = Sequel::Fixture.new
        allow(fix).to receive(:check).and_raise Sequel::Fixture::TablesNotEmptyError
        expect { fix.rollback
        }.to raise_error Sequel::Fixture::RollbackIllegalError,
          "The tables weren't empty to begin with, rollback aborted."
      end
    end

    context "a check has been done and is passing" do
      before do
        @database = double
        @truncable = double
        allow(@truncable).to receive(:count).and_return(0)
        allow(@database).to receive(:[]).and_return @truncable

        @fix = Sequel::Fixture.new
        @fix.connection = @database
        def @fix.stub_data
          @data = { :users => nil, :actions => nil, :extras => nil }
        end
        @fix.stub_data

        expect(@fix.check).to be_truthy
      end

      it "calls truncate on each of the used tables" do
        expect(@truncable).to receive(:truncate).exactly(3).times
        @fix.rollback
      end
    end
  end
end
