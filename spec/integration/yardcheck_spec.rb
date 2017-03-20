# frozen_string_literal: true

require 'open3'

RSpec.describe 'test app integration' do
  let(:report) { remove_color(run_yardcheck) }

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

    Open3.popen3(command) do |_stdin, _stdout, stderr|
      output = stderr.read
    end

    output
  end

  def expect_report(report_substring)
    expect(report).to match(a_string_including(report_substring))
  end

  def remove_color(string)
    string.gsub(/\e\[(?:1\;)?\d+m/, '')
  end

  it 'generates a warning for invalid constant' do
    expect_report('WARNING: Unabled to resolve "What" for lib/test_app.rb:37')
    expect_report('WARNING: Unabled to resolve "Wow" for lib/test_app.rb:37')
  end

  it 'reports expectations' do
    aggregate_failures do
      expect_report('Expected TestApp::Namespace#add to return String but observed Fixnum')
      expect_report('Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum')
      expect_report('Expected TestApp::Namespace#documents_relative to return TestApp::Namespace::Child but observed String')
      expect_report('Expected TestApp::Namespace#improperly_tested_with_instance_double to receive String for value but observed Integer')
      matches = report.scan(/^Expected .+ to return .+ but observed .+$/)
      expect(matches.size).to be(3)
    end
  end
end
