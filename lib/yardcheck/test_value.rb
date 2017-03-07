module Yardcheck
  class TestValue
    include Concord.new(:value)

    def self.process(value)
      if value.is_a?(RSpec::Mocks::InstanceVerifyingDouble)
        InstanceDouble.process(value)
      else
        new(value)
      end
    end

    def is?(klass)
      value.is_a?(klass)
    end

    def type
      value.class
    end

    class InstanceDouble < self
      include Concord.new(:doubled_module)

      def self.process(value)
        new(value.instance_variable_get(:@doubled_module).target)
      end

      def is?(klass)
        doubled_module == klass || doubled_module < klass
      end

      def type
        doubled_module
      end
    end
  end
end
