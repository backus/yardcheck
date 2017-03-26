# frozen_string_literal: true

require_relative './../../lib/test_app'

RSpec.describe TestApp::BlockReturn do
  it 'calls a method which eventually yields and then executes a return' do
    expect(described_class.entrypoint).to be(1)
  end
end
