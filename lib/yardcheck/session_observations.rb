# frozen_string_literal: true

module Yardcheck
  class SessionObservations
    include Concord.new(:events), Adamantium::Flat

    def invalid_param_usage(param_name, typedef)
      param_values.each do |param_case|
        next unless param_case.key?(param_name)
        value = param_case.fetch(param_name)

        next if typedef.match?(value)
        yield(value)
      end
    end

    def invalid_returns(typedef)
      return_values.each do |return_value|
        next if typedef.match?(return_value)
        yield(return_value)
      end
    end

    def test_locations
      collection(:example_location)
    end

    def method_identifier
      collection(:method_identifier).first
    end

    def param_values
      collection(:params)
    end
    memoize :param_values

    def return_values
      uniq(events.reject(&:initialize?).map(&:return_value))
    end
    memoize :return_values

    def collection(attribute)
      uniq(events.map(&attribute))
    end

    def uniq(collection)
      collection.uniq { |item| Object.instance_method(:hash).bind(item).call }
    end
  end # SessionObservations
end # Yardcheck
