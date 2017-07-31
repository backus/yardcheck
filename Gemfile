# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gemspec

group :test do
  gem 'rspec', '~> 3.5'
end

group :lint do
  gem 'rake' # sickill/rainbow#44
  gem 'rubocop', '~> 0.49.1'
  gem 'rubocop-devtools', git: 'https://github.com/backus/rubocop-devtools.git'
  gem 'rubocop-rspec'
end

gem 'guard'
gem 'guard-rspec'
gem 'mutest', '0.0.6'
gem 'mutest-rspec'
