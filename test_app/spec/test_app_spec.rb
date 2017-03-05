# frozen_string_literal: true

require_relative './../lib/test_app'

RSpec.describe TestApp::Namespace do
  it 'does math with instance method' do
    expect(TestApp::Namespace.new.add(2, 3)).to be(5)
  end

  it 'does math with singleton method' do
    expect(TestApp::Namespace.add(2, 3)).to be(5)
  end

  it 'has an undocumented method and that is fine' do
    expect(TestApp::Namespace.new.undocumented).to be(nil)
  end
end
