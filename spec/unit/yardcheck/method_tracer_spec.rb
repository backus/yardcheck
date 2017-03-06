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
        baz.upcase
      end
    end

    class Qux
      def self.singleton_method_example(baz)
        baz.upcase
      end

      def instance_method_example(baz)
        baz.upcase
      end
    end

    tracer = described_class.new(Foo)
    foo    = Foo.new # Capture the activity for this object
    qux    = Qux.new # Ignore this one
    str    = 'Hello'

    tracer.trace do
      foo.instance_method_example(str)
      Foo.singleton_method_example(str)
      qux.instance_method_example(str)
      Qux.singleton_method_example(str)
    end

    expect(tracer.events).to eql([
      {
        type:     :call,
        scope:    :instance,
        method:   :instance_method_example,
        'module': Foo,
        params:   { baz: 'Hello' }
      },
      {
        type:         :return,
        scope:        :instance,
        method:       :instance_method_example,
        'module':     Foo,
        return_value: 'HELLO'
      },
      {
        type:     :call,
        scope:    :class,
        method:   :singleton_method_example,
        'module': Foo.singleton_class,
        params:   { baz: 'Hello' }
      },
      {
        type:         :return,
        scope:        :class,
        method:       :singleton_method_example,
        'module':     Foo.singleton_class,
        return_value: 'HELLO'
      }
    ])
  end
end
