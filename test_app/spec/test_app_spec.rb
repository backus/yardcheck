# frozen_string_literal: true

require_relative './../lib/test_app'

RSpec.describe TestApp::Namespace do
  let(:object) { described_class.new }

  it 'does math with singleton method' do
    expect(described_class.add(2, 3)).to be(5)
  end

  it 'does math with instance method' do
    expect(object.add(2, 3)).to be(5)
  end

  it 'has an undocumented method and that is fine' do
    expect(object.undocumented).to be(nil)
  end

  it 'documents returning the parent but returns child' do
    expect(object.returns_generic).to be_an_instance_of(described_class::Child)
  end

  it 'documents returning a relative namespace incorrectly' do
    expect(object.documents_relative).to be_a(String)
  end

  it 'incorrectly documents a method as accepting Enumerable<String>' do
    expect(object.enumerable_param('hi')).to be(nil)
  end

  it 'properly tests a method with an instance double' do
    expect(object.properly_tested_with_instance_double(instance_double(String))).to be(nil)
  end

  it 'improperly tests a method with an instance double' do
    expect(object.improperly_tested_with_instance_double(instance_double(Integer))).to be(nil)
  end

  it 'tests a method that raises an error instead of returning' do
    expect { object.always_raise }.to raise_error(described_class::AppError)
  end

  it 'improperly documents the param with an invalid const' do
    expect(object.ignoring_invalid_types('hi')).to be(nil)
  end

  it 'returns a literal symbol' do
    expect(object.returns_literal_symbol).to be(:foo)
  end

  it 'returns a truthy value for predicate?' do
    expect(object.truthy_predicate?).to be_truthy
  end

  specify do
    expect(object.tags_without_types(1)).to be(nil)
  end

  it 'special cases Array and Hash' do
    expect(object.special_cases_top_level_constants).to eq([{}])
  end

  it 'is documented as raising AppError but actually raises KeyError' do
    expect { object.invalid_raise_documentation }.to raise_error(KeyError)
  end
end
