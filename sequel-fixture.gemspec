# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sequel-fixture/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Xavier Via"]
  gem.email         = ["xavier.via.canel@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.add_dependency "sequel"         # Stating the obvious
  gem.add_dependency "symbolmatrix"   # Because they have to be easy to use, dammit!

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "fast"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sequel-fixture"
  gem.require_paths = ["lib"]
  gem.version       = Sequel::Fixture::VERSION
end
