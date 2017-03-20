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

  it 'properly tests a method with an instance double' do
    expect(TestApp::Namespace.new.properly_tested_with_instance_double(instance_double(String))).to be(nil)
  end

  it 'improperly tests a method with an instance double' do
    expect(TestApp::Namespace.new.improperly_tested_with_instance_double(instance_double(Integer))).to be(nil)
  end

  it 'tests a method that raises an error instead of returning' do
    expect { TestApp::Namespace.new.always_raise }.to raise_error(TestApp::Namespace::AppError)
  end

  it 'improperly documents the param with an invalid const' do
    expect(TestApp::Namespace.new.ignoring_invalid_types('hi')).to eq([1])
  end
end
