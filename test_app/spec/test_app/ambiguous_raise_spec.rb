# frozen_string_literal: true

require_relative './../../lib/test_app'

RSpec.describe TestApp::AmbiguousRaise do
  it 'calls a method which raises an error' do
    expect(described_class.method1).to be(2)
  end
end
