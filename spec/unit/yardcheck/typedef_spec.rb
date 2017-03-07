# frozen_string_literal: true

RSpec.describe Yardcheck::Typedef do
  def typedef(*types)
    described_class.new(types.map { |type| described_class::Literal.new(type) })
  end

  it 'matches exact type matches' do
    expect(typedef(Integer).match?(Yardcheck::TestValue.new(1))).to be(true)
  end

  it 'matches descendants' do
    parent = Class.new
    child  = Class.new(parent)

    expect(typedef(parent).match?(Yardcheck::TestValue.new(child.new))).to be(true)
  end

  it 'matches union type definitions' do
    aggregate_failures do
      definition = typedef(Integer, String)
      expect(definition.match?(Yardcheck::TestValue.new(1))).to be(true)
      expect(definition.match?(Yardcheck::TestValue.new('hi'))).to be(true)
      expect(definition.match?(Yardcheck::TestValue.new(:hi))).to be(false)
    end
  end
end
