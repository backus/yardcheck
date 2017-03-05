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
    Open3.popen3(command) do |stdin, stdout, stderr|
      warn stderr.read
    end
  end

  def expect_report(report_substring)
    expect { run_yardcheck }.to output(a_string_including(report_substring)).to_stderr
  end

  it 'reports documentation and observed types' do
    expect_report('Expected TestApp::Namespace#add to return String but observed Fixnum')
  end

  it 'reports documentation and observed types' do
    expect_report('Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum')
  end
end
