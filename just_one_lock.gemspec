# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'just_one_lock/version'

Gem::Specification.new do |spec|
  spec.name          = 'just_one_lock'
  spec.version       = JustOneLock::VERSION
  spec.authors       = ['Yury Kotov']
  spec.email         = ['bairkan@gmail.com']
  spec.description   = 'Simple solution to prevent multiple executions using flock'
  spec.summary       = 'Simple solution to prevent multiple executions using flock'
  spec.homepage      = 'http://github.com/beorc/just_one_lock'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_dependency 'gli', '~> 2.11'
end
