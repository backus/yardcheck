# frozen_string_literal: true

RSpec.describe Yardcheck::MethodTracer do
  it 'traces method calls and returns for a namespace' do
    stub_const('Foo', Class.new)
    stub_const('Qux', Class.new)

    class Foo
      def self.singleton_method_example(baz)
        baz.upcase
      end

      def instance_method_example(baz)
        Foo.singleton_method_example(baz)
      end
    end

    class Qux
      def self.singleton_method_example(baz)
        baz.upcase
      end

      def instance_method_example(baz)
        Qux.singleton_method_example(baz)
      end
    end

    tracer = described_class.new(Foo)
    foo    = Foo.new # Capture the activity for this object
    qux    = Qux.new # Ignore this one
    str    = 'Hello'

    tracer.trace do
      foo.instance_method_example(str)
      qux.instance_method_example(str)
    end

    expect(tracer.events).to eq([
      Yardcheck::MethodCall.process(
        scope:    :class,
        selector:   :singleton_method_example,
        namespace: Foo.singleton_class,
        params:   { baz: 'Hello' },
        return_value: 'HELLO',
        example_location: RSpec.current_example.location,
        error_raised:     false
      ),
      Yardcheck::MethodCall.process(
        scope:    :instance,
        selector:   :instance_method_example,
        namespace: Foo,
        params:   { baz: 'Hello' },
        return_value: 'HELLO',
        example_location: RSpec.current_example.location,
        error_raised:     false
      )
    ])
  end
end
