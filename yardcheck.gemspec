# frozen_string_literal: true

require File.expand_path('../lib/yardcheck/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'yardcheck'
  spec.version     = Yardcheck::VERSION
  spec.authors     = %w[John Backus]
  spec.email       = %w[johncbackus@gmail.com]

  spec.summary     = 'Validate YARD docs by running specs'
  spec.description = 'Verify that your YARD @param and @return types are correct'
  spec.homepage    = 'https://github.com/backus/yardcheck'

  spec.files         = `git ls-files`.split("\n")
  spec.require_paths = %w[lib]

  spec.add_dependency 'yard', '~> 0.9'
end
