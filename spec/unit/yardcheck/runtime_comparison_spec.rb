# frozen_string_literal: true

RSpec.describe Yardcheck::RuntimeComparison do
  subject(:comparison) do
    described_class.new(
      Yardcheck::Documentation.new(YardcheckSpec::YARDOCS),
      Yardcheck::SpecObserver.new(method_calls)
    )
  end

  let(:method_calls) do
    [
      {
        scope:        :instance,
        method:       :add,
        module:       TestApp::Namespace,
        params:       {
          left:  Yardcheck::TestValue.new(2),
          right: Yardcheck::TestValue.new(3)
        },
        return_value: Yardcheck::TestValue.new(5)
      },
      {
        scope:        :instance,
        method:       :undocumented,
        module:       TestApp::Namespace,
        params:       {},
        return_value: Yardcheck::TestValue.new(nil)
      },
      {
        scope:        :instance,
        method:       :returns_generic,
        module:       TestApp::Namespace,
        params:       {},
        return_value: Yardcheck::TestValue.new(TestApp::Namespace::Child.new)
      },
      {
        scope:        :instance,
        method:       :documents_relative,
        module:       TestApp::Namespace,
        params:       {},
        return_value: Yardcheck::TestValue.new('str')
      },
      {
        scope:        :instance,
        method:       :enumerable_param,
        module:       TestApp::Namespace,
        params:       { list: Yardcheck::TestValue.new('hi') },
        return_value: Yardcheck::TestValue.new(nil)
      },
      {
        scope:        :instance,
        method:       :properly_tested_with_instance_double,
        module:       TestApp::Namespace,
        params:       {
          value: Yardcheck::TestValue::InstanceDouble.new(String)
        },
        return_value: Yardcheck::TestValue.new(nil)
      },
      {
        scope:        :instance,
        method:       :improperly_tested_with_instance_double,
        module:       TestApp::Namespace,
        params:       {
          value: Yardcheck::TestValue::InstanceDouble.new(Integer)
        },
        return_value: Yardcheck::TestValue.new(nil)
      }
    ].map(&Yardcheck::MethodCall.method(:new))
  end

  it 'exposes invalid return values' do
    comparison.invalid_returns
  end
end
