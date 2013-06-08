require "sequel-fixture"
require "fast"

describe Sequel::Fixture do
  describe ".path" do    
    it "should return 'test/fixtures'" do
      Sequel::Fixture.path.should == "test/fixtures"
    end

    it "should be configurable" do
      Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
      Sequel::Fixture.path.should == File.join(File.dirname(__FILE__), "fixtures")
    end    
  end

  describe ".new" do
    context "a symbol is sent representing a fixture" do
      it "should call load_fixture" do  
        Sequel::Fixture.any_instance.should_receive(:load).with :test
        Sequel::Fixture.new :test
      end
    end

    context "a database connection is passed" do
      it "should call push" do
        Sequel.stub(:connect).and_return Sequel::Database.new
        Sequel::Fixture.any_instance.stub :load
        Sequel::Fixture.any_instance.should_receive :push
        Sequel::Fixture.new :test, Sequel.connect
      end
    end    
    
    context "a database is provided but no fixture" do
      it "should not call push" do
        database = double 'database'
        Sequel::Fixture.any_instance.should_not_receive :push
        Sequel::Fixture.new nil, database
      end
    end
    
    context "a database connection and a valid fixture are passed but a false flag is passed at the end" do
      it "should not push" do
        database = double 'database'
        Sequel::Fixture.any_instance.stub :load
        Sequel::Fixture.any_instance.should_not_receive :push
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

      it "should load the fixture YAML files using SymbolMatrix (third-party)" do
        fix = Sequel::Fixture.new
        fix.stub :check
        SymbolMatrix.should_receive(:new).with "test/fixtures/test/users.yaml"
        SymbolMatrix.should_receive(:new).with "test/fixtures/test/actions.yaml"
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

      it "should fail" do
        Sequel::Fixture.any_instance.stub :push
        database = double 'database'
        database.stub(:[]).and_return double(:count => 0 )
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
    it "check should return true and should not call [] in the passed database" do
      database = stub 'database'
      database.should_not_receive :[]
      
      Sequel::Fixture.any_instance.stub :load
      fix = Sequel::Fixture.new :anything, database, false
      fix.force_checked!.should === true
      fix.check.should === true
    end
  end
  
  describe "#[]" do
    context "a valid fixture has been loaded" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
        
        @fix = Sequel::Fixture.new
        @fix.stub :check
        @fix.load :test
      end
      
      context "a table key is passed" do
        it "should return the Fixture::Table containing the same info as in the matching YAML file" do
          @fix[:users].should be_a Sequel::Fixture::Table
          @fix[:users][0].name.should == "John Doe"
          @fix[:users][0].last_name.should == "Wayne"          
          @fix[:actions][0].action.should == "Walks"
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
          @fix.stub :check
          @fix.load :test
        end
      
        it "should return the SymbolMatrix containing the same info as in the matching YAML file" do
          @fix.users.should be_a Sequel::Fixture::Table
          @fix.users[0].name.should == "John Doe"
          @fix.users[0].last_name.should == "Wayne"
          @fix.actions[0].action.should == "Walks"          
        end

        after do
          Fast.dir.remove! :test
        end
      end
    end    
    
    it "should raise no method error if matches nothing" do
      expect { Sequel::Fixture.new.nothing = "hola"
      }.to raise_error NoMethodError
    end
  end
  
  describe "#fixtures_path" do
    it "should call Sequel::Fixture.path" do
      Sequel::Fixture.should_receive :path
      Sequel::Fixture.new.fixtures_path
    end
  end

  describe "#check" do
    it "should count records on all the used tables" do
      Sequel::Fixture.any_instance.stub :push         # push doesn't get called
      
      database = Sequel::Database.new                 # Fake database connection
      counter = stub                                  # fake table

      database.should_receive(:[]).with(:users).and_return counter
      database.should_receive(:[]).with(:actions).and_return counter      
      counter.should_receive(:count).twice.and_return 0
      
      Sequel.stub(:connect).and_return database
      fix = Sequel::Fixture.new nil, Sequel.connect
      tables = [:users, :actions]
      def fix.stub_data
        @data = { :users => nil, :actions => nil }
      end
      fix.stub_data
      
      fix.check
    end
    
    it "should raise error if the count is different from 0" do
      database = Sequel::Database.new
      counter = stub
      counter.should_receive(:count).and_return 4
      database.stub(:[]).and_return counter
      Sequel::Fixture.any_instance.stub :push

      fix = Sequel::Fixture.new nil, database
      def fix.stub_data
        @data = { :users => nil}
      end
      fix.stub_data
      
      expect { fix.check }.to raise_error Sequel::Fixture::TablesNotEmptyError, 
      "Table 'users' is not empty, tables must be empty prior to testing"
    end
    
    it "should return true if all tables count equals 0" do
      counter  = stub :count => 0
      database = stub
      database.should_receive(:[]).with(:users).and_return counter
      database.should_receive(:[]).with(:actions).and_return counter

      Sequel::Fixture.any_instance.stub :push
      
      fix = Sequel::Fixture.new nil, database
      def fix.stub_data
        @data = { :users => nil, :actions => nil }
      end
      fix.stub_data
      
      fix.check.should === true
    end
    
    context "the check has been done and it passed before" do
      it "should return true even if now tables don't pass" do
        Sequel::Fixture.any_instance.stub :push
        
        @counter = double 'counter'
        @counter.stub :count do
          @amount ||= 0
          @amount += 1
          0 unless @amount > 5
        end
        
        @database = double 'database'
        @database.stub(:[]).and_return @counter

        @fix = Sequel::Fixture.new nil, @database
        def @fix.stub_data
          @data = { :users => nil, :tables => nil, :actions => nil, :schemas => nil }
        end
        @fix.stub_data
        @fix.check.should === true
        @fix.check.should === true  # This looks confusing: let explain. The #count method as defined for the mock
                                    # runs 4 times in the first check. In the second check, it runs 4 times again.
                                    # After time 6 it returns a large amount, making the check fail.
                                    # Of course, the fourth time is never reached since the second check is skipped
      end
    end
    
    context "no fixture has been loaded" do
      it "should fail with a missing fixture exception" do
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
      it "should fail with a missing database connection exception" do
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
      it "should fail with a missing fixture exception" do
        database = double 'database'
        fix = Sequel::Fixture.new nil, database
        expect {fix.check 
        }.to raise_error Sequel::Fixture::MissingFixtureError,
          "No fixture has been loaded, nothing to check"
      end
    end
  end

  describe "#connection" do
    it "should return the Sequel connection passed as argument to the constructor" do
      Sequel::Fixture.any_instance.stub :push
      connection = stub
      fix = Sequel::Fixture.new nil, connection
      fix.connection.should === connection
    end
  end
  
  describe "#connection=" do
    it "sets the connection" do
      fix = Sequel::Fixture.new
      connection = stub
      fix.connection = connection
      fix.connection.should === connection
    end
    
    context "a check has been performed and I attempt to change the connection" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "jane { name: Secret }"
      end
      
      it "should fail" do
        database = double 'database'
        database.stub(:[]).and_return mock(:count => 0)
        Sequel::Fixture.any_instance.stub :push
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
      
      it "should return the fixture data" do
        fix = Sequel::Fixture.new :test
        fix.data.should have_key :users
        fix.data[:users].should be_a Sequel::Fixture::Table
      end
      
      after do
        Fast.dir.remove! :test
      end
    end
    
    context "no fixture has been loaded" do
      it "should return nil" do
        fix = Sequel::Fixture.new 
        fix.data.should be {}
      end
    end
  end
  
  describe "#push" do
    it "should call #check" do
      fix = Sequel::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      fix.should_receive :check
      fix.push
    end

    context "a valid fixture and a database connection are provided" do
      before do
        Sequel::Fixture.path = File.join(File.dirname(__FILE__), "fixtures")
        
        @table    = stub
        @database = stub :[] => @table
        @fix = Sequel::Fixture.new
        @fix.load :test
        @fix.connection = @database
      end
    
      it "should attempt to insert the data into the database" do
        @table.stub :count => 0
        @table.should_receive(:insert).with "name" => "John Doe", "last_name" => "Wayne"
        @table.should_receive(:insert).with "user_id" => 1, "action" => "Walks"
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
      
      it "should insert the <processed> alternative" do
        database = double 'database'
        insertable = double 'table'
        insertable.stub :count => 0
        insertable.should_receive(:insert).with "password" => '35ferwt352'
        database.stub(:[]).and_return insertable
        
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
      
      it "should fail" do
        database = double 'database', :[] => stub( 'table', :count => 0, :truncate => nil  )
        fix = Sequel::Fixture.new :invalid, database, false
        
        expect { fix.push }.to raise_error Sequel::Fixture::MissingProcessedValueError
      end
      
      
      it "should call the rollback" do
        database = double 'database', :[] => stub( 'table', :count => 0, :truncate => nil )
        fix = Sequel::Fixture.new :invalid, database, false
        fix.should_receive :rollback
        expect { fix.push }.to raise_error Sequel::Fixture::MissingProcessedValueError
      end      
      
      after do
        Fast.dir.remove! :test
      end
    end
  end
  
  
  describe "#rollback" do
    it "should check" do
      fix = Sequel::Fixture.new
      def fix.stub_data
        @data = {}
      end
      fix.stub_data
      fix.should_receive :check
      fix.rollback
    end
    
    context "the check is failing" do
      it "should raise a custom error for the rollback" do
        fix = Sequel::Fixture.new
        fix.stub(:check).and_raise Sequel::Fixture::TablesNotEmptyError
        expect { fix.rollback
        }.to raise_error Sequel::Fixture::RollbackIllegalError, 
          "The tables weren't empty to begin with, rollback aborted."
      end
    end
    
    context "a check has been done and is passing" do    
      before do 
        @database = stub
        @truncable = stub
        @truncable.stub :count => 0
        @database.stub(:[]).and_return @truncable
        
        @fix = Sequel::Fixture.new
        @fix.connection = @database
        def @fix.stub_data
          @data = { :users => nil, :actions => nil, :extras => nil }
        end
        @fix.stub_data
        
        @fix.check.should === true
      end
      
      it "should call truncate on each of the used tables" do
        @truncable.should_receive(:truncate).exactly(3).times
        @fix.rollback
      end
    end
  end
end
