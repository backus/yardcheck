# frozen_string_literal: true

RSpec.describe Yardcheck::Typedef do
  def typedef(*types)
    described_class.new(types)
  end

  it 'matches exact type matches' do
    expect(typedef(Integer).match?(Integer)).to be(true)
  end

  it 'matches descendants' do
    parent = Class.new
    child  = Class.new(parent)

    expect(typedef(parent).match?(child)).to be(true)
  end

  it 'matches union type definitions' do
    aggregate_failures do
      definition = typedef(Integer, String)
      expect(definition.match?(Integer)).to be(true)
      expect(definition.match?(String)).to be(true)
      expect(definition.match?(Symbol)).to be(false)
    end
  end

  it 'provides a custom #inspect' do
    expect(typedef(Integer, String).inspect).to eql('Integer | String')
  end
end