# frozen_string_literal: true

module Yardcheck
  class SessionObservations
    include Concord.new(:events), Adamantium::Flat

    def invalid_param_usage(param_name, typedef, &block)
      param_values.each do |param_case|
        next unless param_case.key?(param_name)
        value = param_case.fetch(param_name)

        yield(value) unless typedef.match?(value)
      end
    end

    def invalid_returns(typedef)
      return_values.each do |return_value|
        yield(return_value) unless typedef.match?(return_value)
      end
    end

    def method_identifier
      collection(:method_identifier).first
    end

    def param_values
      collection(:params)
    end
    memoize :param_values

    def return_values
      events.reject(&:initialize?).map(&:return_value).uniq
    end
    memoize :return_values

    def collection(attribute)
      events.map(&attribute).uniq
    end
  end
end # Yardcheck
