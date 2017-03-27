# frozen_string_literal: true

RSpec.describe TestApp::TracepointBug do
  it 'returns 1' do
    expect(described_class.new.method1).to be(1)
  end
end
