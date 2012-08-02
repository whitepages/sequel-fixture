require "sequel-fixture"
require "fast"

describe Sequel::Fixture do
  describe ".path" do
    it "should return 'test/fixtures'" do
      Sequel::Fixture.path.should == "test/fixtures"
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
  end

  describe "#load" do
    context "there is a valid fixture folder setup" do
      before do
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
  end
  
  describe "#[]" do
    context "a valid fixture has been loaded" do
      before do
        Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
        Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
        @fix = Sequel::Fixture.new
        @fix.stub :check
        @fix.load :test
      end
      
      context "a table key is passed" do
        it "should return the SymbolMatrix containing the same info as in the matching YAML file" do
          @fix[:users].should be_a SymbolMatrix
          @fix[:users].john.name.should == "John"
          @fix[:users].john.last_name.should == "Wayne"
          
          @fix[:actions].walk.action.should == "Walks"
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
          Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
          Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
          @fix = Sequel::Fixture.new
          @fix.stub :check
          @fix.load :test
        end
      
        it "should return the SymbolMatrix containing the same info as in the matching YAML file" do
          @fix.users.should be_a SymbolMatrix
          @fix.users.john.name.should == "John"
          @fix.users.john.last_name.should == "Wayne"
          
          @fix.actions.walk.action.should == "Walks"          
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
      
      expect { fix.check
      }.to raise_error Sequel::Fixture::TablesNotEmptyError, 
        "The table 'users' is not empty, all tables should be empty prior to testing"
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
      before do
        Sequel::Fixture.any_instance.stub :push
        
        @counter = stub :count => 0
        @database = stub :[] => @counter
        @fix = Sequel::Fixture.new nil, @database
        def @fix.stub_data
          @data = { :users => nil, :tables => nil, :actions => nil, :schemas => nil }
        end
        @fix.stub_data
        
        @fix.check.should === true
      end
      
      it "should return true even if now tables don't pass" do
        @counter = stub :count => 4
        
        @fix.check.should === true
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
  
  describe "#connnection=" do
    it "sets the connection" do
      fix = Sequel::Fixture.new
      connection = stub
      fix.connection = connection
      fix.connection.should === connection
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
        Fast.file.write "test/fixtures/test/users.yaml", "john: { name: John, last_name: Wayne }"
        Fast.file.write "test/fixtures/test/actions.yaml", "walk: { user_id: 1, action: Walks }"
        @table    = stub
        @database = stub :[] => @table
        @fix = Sequel::Fixture.new
        @fix.load :test
        @fix.connection = @database
      end
    
      it "should attempt to insert the data into the database" do
        @table.stub :count => 0
        @table.should_receive(:insert).with :name => "John", :last_name => "Wayne"
        @table.should_receive(:insert).with :user_id => 1, :action => "Walks"
        @fix.push
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
