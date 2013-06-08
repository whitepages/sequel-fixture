class Sequel::Fixture
  
  # === Description
  # Simplifies the hash in order to insert it into the database
  # (Note: I'm well aware that this functionality belongs in a dependency)
  #
  def simplify(the_hash)    
    the_returned_hash = {}
    
    the_hash.each do |key, value|
      if value.is_a? Hash
        unless value.has_key?("processed") || value.has_key?(:processed)
          raise MissingProcessedValueError.new "The processed value to insert into the db is missing from the field '#{key}', aborting", key 
        end
        the_returned_hash[key] = value["processed"] || value[:processed]
      else
        the_returned_hash[key] = value
      end
    end
    return the_returned_hash
  end  
end
