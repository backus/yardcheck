# frozen_string_literal: true

require 'pathname'

module YardcheckSpec
  ROOT = Pathname.new(__dir__).parent
  TEST_APP = ROOT.join('test_app')

  Yardcheck::Documentation.load_yard
  test_app_yardoc = TEST_APP.join('.yardoc')
  YARD::Registry.load!(test_app_yardoc.to_s)
  YARDOCS = YARD::Registry.all(:method)
end # YardcheckSpec

$LOAD_PATH.unshift(YardcheckSpec::TEST_APP.join('lib').to_s)

require 'test_app'
