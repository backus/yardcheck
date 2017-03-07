module Yardcheck
  class MethodCall
    include Anima.new(:scope, :selector, :namespace, :params, :return_value)

    def self.process(params:, return_value:, **attributes)
      params =
        params.map do |key, value|
          [key, TestValue.process(value)]
        end.to_h

      return_value = TestValue.process(return_value)

      new(params: params, return_value: return_value, **attributes)
    end

    def method_identifier
      [namespace, selector, scope]
    end

    def initialize?
      selector == :initialize && scope == :instance
    end
  end
end
