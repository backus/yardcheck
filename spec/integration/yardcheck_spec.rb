# frozen_string_literal: true

RSpec.describe 'test app integration' do
  it 'reports documentation and observed types' do
    Bundler.with_clean_env do
      Dir.chdir('test_app') do
        puts Dir.pwd
        puts "bundle install --gemfile=#{File.join(Dir.pwd, 'Gemfile')}"
        Kernel.system("bundle install --gemfile=#{File.join(Dir.pwd, 'Gemfile')}")
        Kernel.system('bundle exec yardcheck')
      end
    end
  end
end
