module Yardcheck
  module ObservedValue
    def self.build(object)
      if object.is_a?(RSpec::Mocks::InstanceVerifyingDouble)
        InstanceDouble.new(object)
      else
        object
      end
    end

    class InstanceDouble
      include Concord.new(:double)

      def is_a?(klass)
        target_class == klass || target_class < klass
      end

      def class
        target_class
      end

      private

      def target_class
        Object.const_get(doubled_module.description)
      end

      def expired?
        double.instance_variable_get(:@__expired)
      end

      def doubled_module
        double.instance_variable_get(:@doubled_module)
      end
    end
  end
end
