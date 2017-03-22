# frozen_string_literal: true

require 'pathname'
require 'bundler'
require 'timeout'

Bundler.with_clean_env { system('cd test_app && yard --no-cache --no-output > /dev/null') }

begin
  require 'mutest'

  module Mutest
    class Selector
      class Expression < self
        def call(_subject)
          integration.all_tests
        end
      end # Expression
    end # Selector
  end # Mutest
rescue LoadError
end

module YardcheckSpec
  ROOT = Pathname.new(__dir__).parent
  TEST_APP = ROOT.join('test_app')

  Yardcheck::Documentation.load_yard
  test_app_yardoc = TEST_APP.join('.yardoc')
  YARD::Registry.load!(test_app_yardoc.to_s)
  YARDOCS = YARD::Registry.all(:method)
end # YardcheckSpec

RSpec.configure do |config|
  # Define metadata for all tests which live under spec/integration
  config.define_derived_metadata(file_path: %r{\bspec/integration/}) do |metadata|
    # Set the type of these tests as 'integration'
    metadata[:type]   = :integration

    # Define metadata for mutant so it knows to never run these tests
    metadata[:mutest] = false
  end

  config.around(file_path: %r{\bspec/unit/}) do |example|
    Timeout.timeout(0.1, &example)
  end
end

$LOAD_PATH.unshift(YardcheckSpec::TEST_APP.join('lib').to_s)

require 'test_app'
