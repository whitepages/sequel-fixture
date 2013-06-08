require "sequel"
require "symbolmatrix"
require "fast"

require "sequel-fixture/version"
require "sequel-fixture/exceptions"
require "sequel-fixture/util"
require "sequel-fixture/table"

module Sequel; end

class Sequel::Fixture
  
  # === Description
  # Returns the current path to the fixtures folder
  #
  def self.path
    @@path ||= "test/fixtures"
  end

  
  # === Description
  # Set the current path of the fixtures folder
  #
  def self.path=(path)
    @@path = path
  end
  
  # === Description
  # Initializes the fixture handler
  # Accepts optionally a symbol as a reference to the fixture
  # and a Sequel::Database connection
  def initialize(fixture = nil, connection = nil, option_push = true)
    @schema = {}
    @data = {}
    
    load(fixture) if fixture
    
    @connection = connection if connection
    push if fixture && connection && option_push
  end

  
  # === Description
  # Loads the fixture files into this instance
  #
  def load(fixture)
    raise LoadingFixtureIllegal, "A check has already been made, loading a different fixture is illegal" if @checked
    
    Fast.dir("#{fixtures_path}/#{fixture}").files.to.symbols.each do |file|
      @data ||= {}
      @schema ||= {}

      file_data = SymbolMatrix.new "#{fixtures_path}/#{fixture}/#{file}.yaml"

      if file_data
        @data[file] = Table.new(file_data[:data]) if file_data.key?(:data)
        @schema[file] = file_data[:schema] if file_data.key?(:schema)
      end
    end
  end

  
  # === Description
  # Returns the current fixtures path where Sequel::Fixture looks for fixture folders
  #
  def fixtures_path
    Sequel::Fixture.path
  end


  # === Description
  # For enabling discovery of tables
  #
  def method_missing(key, *args)
    return @data[key] if @data && @data.has_key?(key)
    return super
  end    
  
  # === Description
  # Returns the SymbolMatrix with the data referring to that table
  #
  def [](reference)
    @data[reference]
  end
  
  
  # === Description
  # Forces the check to pass. Dangerous!
  #
  def force_checked!
    @checked = true
  end

  
  # === Description
  # Assures that the tables are empty before proceeding
  #
  def check
    return @checked if @checked # If already checked, it's alright

    raise MissingFixtureError, "No fixture has been loaded, nothing to check" unless @data.length > 0
    raise MissingConnectionError, "No connection has been provided, impossible to check" unless @connection
    
    @data.each_key do |table|
      if @connection[table].count != 0
        raise TablesNotEmptyError, "Table '#{table}' is not empty, tables must be empty prior to testing"
      end
    end
    return @checked = true
  end

  
  # === Description
  # Initializes fixture schema and Inserts the fixture data into the corresponding
  # tables
  #
  def push
    check

    @schema.each do |table, matrix|
      push_schema(table, matrix)
    end
    
    @data.each do |table_name, table_data|
      table_data.rows.each do |values|
        begin
          @connection[table_name].insert(simplify(values.to_h))
        rescue MissingProcessedValueError => m
          rollback
          raise MissingProcessedValueError, "In record '#{values.to_h}' to be inserted into '#{table_name}', the processed value of field '#{m.field}' is missing, aborting."
        rescue NoMethodError => e
          raise IllegalFixtureFormat, "In record '#{values}', data must be formatted as arrays of hashes. Check 'data' section in '#{table_name}.yaml'"
        end
      end
    end
  end

  
  # === Description 
  # Create the schema in our DB connection based on the schema values
  #  
  def push_schema(table, values)
    ## Lets passively ignore the schema if the table already exists
    return if @connection.table_exists?(table.to_sym)

    ## Find the primary key
    pkey_data = nil
    values.each do |column_def|
      pkey_data = column_def if column_def["primary_key"]
    end
    
    ## Create the table with the primary key
    @connection.create_table(table) do
      column(pkey_data["name"].to_sym, pkey_data["type"].to_sym)
    end

    ## Add the rest of the columns
    values.each do |column_def|
      unless column_def["primary_key"]
        @connection.alter_table(table) { add_column(column_def["name"].to_sym, column_def["type"].to_sym) }
      end
    end
  end
  
  
  # === Description
  # Empties the tables, only if they were empty to begin with
  #
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

  
  # === Description
  # Sets the connection. Raises an ChangingConnectionIllegal exception if this fixture has
  # already been checked
  #
  def connection=(the_connection)
    if @checked
      raise ChangingConnectionIllegal, "Illegal to change connection after check has already been performed"
    end
    @connection = the_connection
  end

  attr_reader :connection
  attr_reader :data
  attr_reader :schema  
end
