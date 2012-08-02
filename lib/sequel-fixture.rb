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
    def initialize fixture = nil, connection = nil
      load fixture if fixture
      
      if connection
        @connection = connection
        push
      end
    end
    
    # Loads the fixture files into this instance
    def load fixture
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
      @data.each_key do |table|
        raise TablesNotEmptyError, "The table '#{table}' is not empty, all tables should be empty prior to testing" if @connection[table].count != 0
      end
      return true
    end
    
    # Inserts the fixture data into the corresponding tables
    def push
      check
      
      @data.each do |table, matrix|
        matrix.each do |element, values|
          @connection[table].insert values.to_hash
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
    
    attr_accessor :connection    

    class TablesNotEmptyError < StandardError; end
    class RollbackIllegalError < StandardError; end
  end
end
