# frozen_string_literal: true

require_relative './../lib/test_app'

RSpec.describe TestApp do
  it 'says hello' do
    expect { TestApp.new.hello("John") }.to output("Hello, John\n").to_stdout
  end

  it 'says goodbye' do
    expect { TestApp.new.bye("John") }.to output("Goodbye, John\n").to_stdout
  end
end
