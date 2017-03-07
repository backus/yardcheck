# frozen_string_literal: true

RSpec.describe Yardcheck::MethodCall do
  it 'unwraps doubles' do
    stub_const('Bar', Class.new)

    processed =
      described_class.process(
        scope:    :instance,
        method:   :foo,
        'module': Bar,
        params:   { baz: instance_double(String) },
        return_value: instance_double('Symbol')
      )

    expect(processed).to eql(
      described_class.new(
        scope:    :instance,
        method:   :foo,
        'module': Bar,
        params:   { baz: Yardcheck::TestValue::InstanceDouble.new(String) },
        return_value: Yardcheck::TestValue::InstanceDouble.new(Symbol)
      )
    )
  end
end
