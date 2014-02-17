# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sequel-fixture/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sebastian Beresniewicz"]
  gem.email         = ["sebastianb@whitepages.com"]
  gem.description   = %q{Flexible fixtures for the Sequel Gem inspired in Rails 2 fixtures}
  gem.summary       = %q{Flexible fixtures for the Sequel Gem inspired in Rails 2 fixtures}
  gem.homepage      = "http://github.com/whitepages/sequel-fixture"

  gem.add_dependency "sequel"         # Stating the obvious
  gem.add_dependency "symbolmatrix"   # Because its easy to use

  gem.add_development_dependency "rspec"
  
  # Fast was needed,as a testing gem, there's no problem with extra load here
  gem.add_development_dependency "fast"  

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sequel-fixture"
  gem.require_paths = ["lib"]
  gem.version       = Sequel::Fixture::VERSION
end
