# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'super_cache/version'

Gem::Specification.new do |gem|
  gem.name          = "super_cache"
  gem.version       = SuperCache::VERSION
  gem.authors       = ["ShiningRay"]
  gem.email         = ["tsowly@hotmail.com"]
  gem.description   = %q{A simple caching middleware for rails}
  gem.summary       = %q{A simple caching middleware for rails, with solution for dog-pile effect}
  gem.homepage      = "https://github.com/shiningray/super_cache"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
