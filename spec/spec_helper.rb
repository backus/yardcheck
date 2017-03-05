require 'pathname'

module YardcheckSpec
  ROOT = Pathname.new(__dir__).parent
  TEST_APP = ROOT.join('test_app')

  test_app_yardoc = TEST_APP.join('.yardoc')
  YARD::Registry.load!(test_app_yardoc.to_s)
  YARDOCS = YARD::Registry.all(:method)
end

$LOAD_PATH.unshift(YardcheckSpec::TEST_APP.join('lib').to_s)

require 'test_app'
