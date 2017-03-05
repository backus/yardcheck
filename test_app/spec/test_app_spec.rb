# frozen_string_literal: true

require_relative './../lib/test_app'

RSpec.describe TestApp do
  it 'does math with instance method' do
    expect(TestApp.new.add(2, 3)).to be(5)
  end

  it 'does math with singleton method' do
    expect(TestApp.add(2, 3)).to be(5)
  end
end
