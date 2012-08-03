require "sequel"
require "symbolmatrix"

require "sequel-fixture/version"

module Sequel

  # Fixture managing class for Sequel
  class Fixture
    ## Class methods
    
    # Returns the current path to the fixtures folder
    def self.path
      @@path ||= "test/fixtures"
    end
    
    
    ## Instance methods
    
    # Initializes the fixture handler
    # Accepts optionally a symbol as a reference to the fixture
    # and a Sequel::Database connection
    def initialize fixture = nil, connection = nil, option_push = true
      load fixture if fixture
      
      @connection = connection if connection
      push if fixture && connection && option_push
    end
    
    # Loads the fixture files into this instance
    def load fixture
      raise LoadingFixtureIllegal, "A check has already been made, loading a different fixture is illegal" if @checked
      
      Fast.dir("#{fixtures_path}/#{fixture}").files.to.symbols.each do |file|
        @data ||= {}
        @data[file] = SymbolMatrix.new "#{fixtures_path}/#{fixture}/#{file}.yaml"
      end
    end
    
    # Returns the current fixtures path where Sequel::Fixtures looks for fixture folders
    def fixtures_path
      Sequel::Fixture.path
    end
    
    # Returns the SymbolMatrix with the data referring to that table
    def [] reference
      @data[reference]
    end
    
    # Method missing, for enabling discovery of tables
    def method_missing s, *args
      return @data[s] if @data && @data.has_key?(s)
      return super
    end
    
    # Assures that the tables are empty before proceeding
    def check
      return @checked if @checked # If already checked, it's alright

      raise MissingFixtureError, "No fixture has been loaded, nothing to check" unless @data
      raise MissingConnectionError, "No connection has been provided, impossible to check" unless @connection
      
      @data.each_key do |table|
        raise TablesNotEmptyError, "The table '#{table}' is not empty, all tables should be empty prior to testing" if @connection[table].count != 0
      end
      return @checked = true
    end
    
    # Inserts the fixture data into the corresponding tables
    def push
      check
      
      @data.each do |table, matrix|
        matrix.each do |element, values|
          begin
            @connection[table].insert simplify values.to_hash
          rescue MissingProcessedValueError => m
            rollback
            raise MissingProcessedValueError, "In record '#{element}' to be inserted into '#{table}', the processed value of field '#{m.field}' is missing, aborting"
          end
        end
      end
    end
    
    # Empties the tables, only if they were empty to begin with
    def rollback
      begin
        check
        
        @data.each_key do |table|
          @connection[table].truncate
        end
      rescue TablesNotEmptyError => e
        raise RollbackIllegalError, "The tables weren't empty to begin with, rollback aborted."
      end
    end
    
    attr_reader :connection    
    
    # Sets the connection. Raises an ChangingConnectionIllegal exception if this fixture has already been checked
    def connection= the_connection
      raise ChangingConnectionIllegal, "A check has already been performed, changing the connection now is illegal" if @checked
      @connection = the_connection
    end
    
    attr_reader :data
    
    # Simplifies the hash in order to insert it into the database
    # (Note: I'm well aware that this functionality belongs in a dependency)
    def simplify the_hash
      the_returned_hash = {}
      the_hash.each do |key, value|
        if value.is_a? Hash
          unless value.has_key? :processed
            raise MissingProcessedValueError.new "The processed value to insert into the db is missing from the field '#{key}', aborting", key 
          end
          the_returned_hash[key] = value[:processed]
        else
          the_returned_hash[key] = value
        end
      end
      return the_returned_hash
    end

    class TablesNotEmptyError < StandardError; end
    class RollbackIllegalError < StandardError; end
    class MissingFixtureError < StandardError; end
    class MissingConnectionError < StandardError; end
    class LoadingFixtureIllegal < StandardError; end
    class ChangingConnectionIllegal < StandardError; end
    class MissingProcessedValueError < StandardError
      attr_accessor :field
      def initialize message, field = nil
        @field = field
        super message
      end
    end
  end
end
