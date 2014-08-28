# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'just_one_lock/version'

Gem::Specification.new do |spec|
  spec.name          = "just_one_lock"
  spec.version       = JustOneLock::VERSION
  spec.authors       = ["Adam Stankiewicz, Yury Kotov"]
  spec.email         = ["bairkan@gmail.com"]
  spec.description   = %q{Simple solution to prevent multiple executions using flock}
  spec.summary       = %q{Simple solution to prevent multiple executions using flock}
  spec.homepage      = "http://github.com/beorc/just_one_lock"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
