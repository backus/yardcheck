# frozen_string_literal: true

module Yardcheck
  class Observation
    include Concord.new(:documentation, :event)

    def violations
      param_violations + return_violations + raise_violations
    end

    def source_code
      documentation.source
    end

    def source_location
      documentation.location_pointer
    end

    def test_location
      event.example_location
    end

    def method_shorthand
      documentation.shorthand
    end

    def documented_param(name)
      documentation.params.fetch(name)
    end

    def observed_param(name)
      event.params.fetch(name)
    end

    def documented_return_type
      documentation.return_type
    end

    def documented_raise_type
      documentation.raise_type
    end

    def actual_return_type
      event.return_value.type
    end

    def actual_raise_type
      event.exception.type
    end

    def documentation_warnings
      documentation.warnings
    end

    private

    def param_violations
      overlapping_keys = documentation.params.keys & event.params.keys

      overlapping_keys.map do |key|
        type_definition = documentation.params.fetch(key)
        test_value      = event.params.fetch(key)

        next if type_definition.match?(test_value)
        Violation::Param.new(key, self)
      end
    end

    def return_violations
      invalid_return? ? [Violation::Return.new(self)] : []
    end

    def raise_violations
      invalid_raise? ? [Violation::Raise.new(self)] : []
    end

    def invalid_raise?
      documentation.raise_type &&
        event.raise?           &&
        !documentation.raise_type.match?(event.exception)
    end

    def invalid_return?
      documentation.return_type                               &&
        event.return?                                         &&
        !documentation.return_type.match?(event.return_value) &&
        !event.initialize?                                    &&
        !documentation.predicate_method?                      &&
        !possible_tracepoint_bug?
    end

    def possible_tracepoint_bug?
      return false unless event.return_value.is?(nil)

      documentation.processed_source.tracepoint_bug_candidate?
    end
  end # Observation
end # Yardcheck
