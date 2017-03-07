module Yardcheck
  class MethodCall
    include Anima.new(:scope, :method, :module, :params, :return_value)

    def self.process(params:, return_value:, **attributes)
      params = params.map { |key, value| [key, process_value(value)] }.to_h
      return_value = process_value(return_value)

      new(params: params, return_value: return_value, **attributes)
    end

    def self.process_value(value)
      if value.is_a?(RSpec::Mocks::InstanceVerifyingDouble)
        InstanceDouble.new(
          value.instance_variable_get(:@doubled_module).target
        )
      else
        RealValue.new(value)
      end
    end

    def method_identifier
      [self.module, self.method, scope]
    end

    class RealValue
      include Concord.new(:value)

      def is?(klass)
        value.is_a?(klass)
      end

      def type
        value.class
      end
    end

    class InstanceDouble
      include Concord.new(:doubled_module)

      def is?(klass)
        doubled_module == klass || doubled_module < klass
      end

      def type
        doubled_module
      end
    end
  end
end
