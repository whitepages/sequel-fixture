require "sequel-fixture"
require "fast"

describe Sequel::Fixture do
  # This should go in a dependency, pending refactoring TODO
  describe "#simplify" do
    context "when receiving a multidimensional hash containing a field with raw and processed" do
      it "converts it in a simple hash using the processed value as replacement" do
        base_hash = {
          :name => "Jane",
          :band => "Witherspoons",
          :pass => {
            :raw => "secret",
            :processed => "53oih7fhjdgj3f8="
          },
          :email => {
            :raw => "Jane@gmail.com ",
            :processed => "jane@gmail.com"
          }
        }

        fix = Sequel::Fixture.new
        simplified = fix.simplify(base_hash)
        expect(simplified).to eq({
          :name => "Jane",
          :band => "Witherspoons",
          :pass => "53oih7fhjdgj3f8=",
          :email => "jane@gmail.com"
        })
      end
    end

    context "the multidimensional array is missing the processed part of the field" do
      it "raises an exception" do
        base_hash = {
          :name => "Jane",
          :pass => {
            :raw => "secret",
            :not_processed => "53oih7fhjdgj3f8="
          },
          :email => {
            :raw => "Jane@gmail.com ",
            :processed => "jane@gmail.com"
          }
        }

        fix = Sequel::Fixture.new
        expect { fix.simplify(base_hash)
        }.to raise_error Sequel::Fixture::MissingProcessedValueError,
          "The processed value to insert into the db is missing from the field 'pass', aborting"
      end
    end
  end
end
