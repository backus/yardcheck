# frozen_string_literal: true

module Yardcheck
  class SessionObservations
    include Concord.new(:events), Adamantium::Flat

    def invalid_param_usage(param_name, typedef, &block)
      param_values
        .select { |param_case| param_case.key?(param_name)  }
        .map    { |param_case| param_case.fetch(param_name) }
        .reject { |param_value| typedef.match?(param_value)   }
        .each(&block)
    end

    def invalid_returns(typedef, &block)
      return_values
        .reject { |return_value| typedef.match?(return_value)   }
        .each(&block)
    end

    def method_identifier
      unique_events = events.map do |event|
        event.fetch_values(:module, :method, :scope)
      end.uniq

      fail 'wtf?' unless unique_events.one?

      unique_events.first
    end

    def param_values
      events_for(:call).map do |params:, **|
        params.map do |key, value|
          [key, ObservedValue.build(value)]
        end.to_h
      end
    end
    memoize :param_values

    def return_values
      events_for(:return).map do |return_value:, **|
        ObservedValue.build(return_value)
      end.uniq
    end
    memoize :return_values

    private

    def events_for(event_type)
      events
    end
  end

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
end # Yardcheck
