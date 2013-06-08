module Sequel; end

class Sequel::Fixture
  
  # === Description
  # Class which represents the actual fixture data in a table
  #
  class Table
    def initialize(data)
      @data = data
    end

    def [](row)
      Sequel::Fixture::Row.new(@data[row])
    end
    
    def rows
      @data
    end
  end

  
  # === Description
  # Class which represents a single row in a fixture table.
  #
  class Row
    def initialize(row)
      @data = row
    end
    
    # === Description
    # Method missing, for enabling discovery of columns within a row
    #
    def method_missing(s, *args)
      key = s.to_s
      return @data[key] if @data && @data.has_key?(key)
      return super
    end    
  end
end
