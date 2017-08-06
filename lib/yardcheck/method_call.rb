# frozen_string_literal: true

module Yardcheck
  class MethodCall
    include AbstractType, Anima.new(
      :scope,
      :selector,
      :namespace,
      :params,
      :example_metadata
    )

    def self.process(params:, **attributes)
      params =
        params.map do |key, value|
          [key, TestValue.process(value)]
        end.to_h

      new(params: params, **attributes)
    end

    def example_location
      example_metadata.fetch(:location)
    end

    def method_identifier
      [namespace, selector, scope]
    end

    def initialize?
      selector == :initialize && scope == :instance
    end

    def raise?
      false
    end

    def return?
      false
    end

    class Return < self
      include anima.add(:return_value)

      def self.process(return_value:, **kwargs)
        super(return_value: TestValue.process(return_value), **kwargs)
      end

      def return?
        true
      end
    end # Return

    class Raise < self
      include anima.add(:exception)

      def self.process(exception:, **kwargs)
        super(exception: TestValue.process(exception), **kwargs)
      end

      def raise?
        true
      end
    end # Raise

    class Jump < self
    end # Jump
  end # MethodCall
end # Yardcheck
