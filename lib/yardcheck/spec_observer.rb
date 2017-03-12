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

    def associate_with(documentation)
      docs    = documentation.method_objects.group_by(&:method_identifier)
      calls   = events.group_by(&:method_identifier)
      overlap = docs.keys & calls.keys

      overlap.flat_map do |key|
        method_object = docs.fetch(key).first
        calls.fetch(key).map { |call| Observation.new(method_object, call) }
      end
    end
  end # SpecObserver
end # Yardcheck
