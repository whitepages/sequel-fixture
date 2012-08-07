# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sequel-fixture/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Via"]
  gem.email         = ["xavier.via.canel@gmail.com"]
  gem.description   = %q{Flexible fixtures for the Sequel Gem inspired in Rails 2 fixtures}
  gem.summary       = %q{Flexible fixtures for the Sequel Gem inspired in Rails 2 fixtures}
  gem.homepage      = "http://github.com/Fetcher/sequel-fixture"

  gem.add_dependency "sequel"         # Stating the obvious
  gem.add_dependency "symbolmatrix"   # Because they have to be easy to use, dammit!
  gem.add_dependency "fast"           # Fast was needed. This is a testing gem, there's no problem with extra load

  gem.add_development_dependency "rspec"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sequel-fixture"
  gem.require_paths = ["lib"]
  gem.version       = Sequel::Fixture::VERSION
end
