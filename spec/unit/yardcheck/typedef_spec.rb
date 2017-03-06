# frozen_string_literal: true

RSpec.describe Yardcheck::Typedef do
  def typedef(*types)
    described_class.new(types.map { |type| described_class::Literal.new(type) })
  end

  it 'matches exact type matches' do
    expect(typedef(Integer).match?(1)).to be(true)
  end

  it 'matches descendants' do
    parent = Class.new
    child  = Class.new(parent)

    expect(typedef(parent).match?(child.new)).to be(true)
  end

  it 'matches union type definitions' do
    aggregate_failures do
      definition = typedef(Integer, String)
      expect(definition.match?(1)).to be(true)
      expect(definition.match?('hi')).to be(true)
      expect(definition.match?(:hi)).to be(false)
    end
  end
end
