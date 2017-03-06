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

  it 'documents returning the parent but returns child' do
    expect(TestApp::Namespace.new.returns_generic).to be_an_instance_of(TestApp::Namespace::Child)
  end

  it 'documents returning a relative namespace incorrectly' do
    expect(TestApp::Namespace.new.documents_relative).to be_a(String)
  end

  it 'incorrectly documents a method as accepting Enumerable<String>' do
    expect(TestApp::Namespace.new.enumerable_param('hi')).to be(nil)
  end
end
