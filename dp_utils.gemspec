# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dp_utils/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sam Kong"]
  gem.email         = ["sam.s.kong@gmail.com"]
  gem.description   = %q{Sam Kong's utilities}
  gem.summary       = %q{Sam Kong's utilities}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "dp_utils"
  gem.require_paths = ["lib"]
  gem.version       = DpUtils::VERSION
end
