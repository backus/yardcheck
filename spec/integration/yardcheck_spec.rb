# frozen_string_literal: true

require 'open3'

RSpec.describe 'test app integration' do
  def run_yardcheck
    Bundler.with_clean_env do
      Dir.chdir('test_app') do
        system("bundle install --gemfile=#{File.join(Dir.pwd, 'Gemfile')}")
        system('bundle exec yardcheck --namespace TestApp --include lib --require test_app')
      end
    end
  end

  def system(command)
    output = nil

    Open3.popen3(command) do |stdin, stdout, stderr|
      output = stderr.read
    end

    output
  end

  def expect_report(report_substring)
    expect(run_yardcheck).to match(a_string_including(report_substring))
  end

  it 'reports expectation for instance method' do
    expect_report('Expected TestApp::Namespace#add to return String but observed Fixnum')
  end

  it 'reports expectation for singleton method' do
    expect_report('Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum')
  end

  it 'reports expectation for method that should have returned an instance of a relative constant' do
    expect_report('Expected TestApp::Namespace#documents_relative to return TestApp::Namespace::Child but observed String')
  end

  it 'does not report more than two violations' do
    matches = run_yardcheck.scan(/^Expected .+ to return .+ but observed .+$/)
    expect(matches.size).to be(3)
  end
end
