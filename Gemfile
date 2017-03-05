# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version').chomp

gemspec

gem 'pry', git: 'https://github.com/mvz/pry.git', branch: 'strip-readline-prompt-ignore-codes'

group :test do
  gem 'rspec', '~> 3.5'
end

group :lint do
  gem 'rubocop',          git: 'https://github.com/bbatsov/rubocop.git'
  gem 'rubocop-devtools', git: 'https://github.com/backus/rubocop-devtools.git'
  gem 'rubocop-rspec',    git: 'https://github.com/backus/rubocop-rspec.git'
end
