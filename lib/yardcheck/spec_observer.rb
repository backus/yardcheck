# frozen_string_literal: true

module Yardcheck
  class SpecObserver
    include Concord.new(:events), Memoizable

    def self.run(rspec_arguments, namespace)
      tracer      = MethodTracer.new(Object.const_get(namespace))
      test_runner = TestRunner.new(rspec_arguments)

      test_runner.wrap_test(tracer.method(:trace))
      test_runner.run

      new(tracer.events)
    end

    def types
      method_calls
    end
    memoize :types

    private

    def method_calls
      events
        .group_by { |entry| entry.method_identifier }
        .map { |_, observations| SessionObservations.new(observations) }
    end
  end # SpecObserver
end # Yardcheck
