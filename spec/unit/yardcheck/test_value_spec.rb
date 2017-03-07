# frozen_string_literal: true

RSpec.describe Yardcheck::TestValue do
  it 'just wraps normal values' do
    expect(described_class.process(1)).to eql(described_class.new(1))
  end

  it 'extracts the namespace from instance doubles' do
    expect(described_class.process(instance_double(String))).to eql(
      described_class::InstanceDouble.new(String)
    )
  end

  it 'extracts the name from doubles' do
    expect(described_class.process(double(:foo))).to eql(
      described_class::Double.new(:foo)
    )
  end

  it 'handles anonymous doubles' do
    expect(described_class.process(double)).to eql(
      described_class::Double.new('(anonymous)')
    )
  end
end
