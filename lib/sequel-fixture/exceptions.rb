class Sequel::Fixture
  class IllegalFixtureFormat < StandardError; end
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
