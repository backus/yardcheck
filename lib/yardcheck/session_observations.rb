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
      unique_events = events.map(&:method_identifier).uniq

      fail 'wtf?' unless unique_events.one?

      unique_events.first
    end

    def param_values
      events_for(:call).map do |event|
        event.params
      end
    end
    memoize :param_values

    def return_values
      events_for(:return).map do |event|
        event.return_value
      end.uniq
    end
    memoize :return_values

    private

    def events_for(event_type)
      events
    end
  end
end # Yardcheck
