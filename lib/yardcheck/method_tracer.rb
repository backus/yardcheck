# frozen_string_literal: true

module Yardcheck
  class MethodTracer
    include Concord.new(:namespace, :seen, :call_stack), Memoizable

    def initialize(namespace)
      super(namespace, [], [])

      # When an exception is raised it isn't clear when it has been eventually rescued.
      # We set `@ambiguous_exception_state` to `true` when we have observed an exception
      # and have not seen a non `nil` return.
      @ambiguous_exception_state = false

      # A block passed from one method down to another method can trigger a return of the
      # originating method. This triggers a waterfall of `nil` returns because each method
      # shortcircuits. Similar to `ambiguous_exception_state` we need to also track ambiguous
      # block return state.
      @ambiguous_block_return_state = false
    end

    def trace(&block)
      tracer.enable(&block)
    end

    def events
      seen.freeze
    end

    private

    attr_reader :ambiguous_exception_state, :ambiguous_block_return_state

    def tracer
      TracePoint.new(:call, :return, :raise, :b_return) do |event|
        tracer.disable do
          process(event) if target?(event.defined_class)
        end
      end
    end
    memoize :tracer

    def process(trace_event)
      case trace_event.event
      when :call     then process_call(trace_event)
      when :return   then process_return(trace_event)
      when :raise    then process_raise
      when :b_return then process_block_return
      end
    end

    def process_call(trace_event)
      # If we observe a method call then we are certainly no longer inside of a
      # bubbling up of early returns
      @ambiguous_block_return_state = false

      parameter_names =
        trace_event
          .defined_class
          .instance_method(trace_event.method_id)
          .parameters.map { |_, name| name }

      scope  = trace_event.binding
      params =
        scope
          .local_variables
          .select { |lvar| parameter_names.include?(lvar) }
          .map { |lvar| [lvar, scope.local_variable_get(lvar)] }.to_h

      event = event_details(trace_event).update(params: params)
      call_stack.push(event)
    end

    def process_return(trace_event)
      return_value = trace_event.return_value

      # If we observe a non `nil` return value then it is no longer possible that we are observing
      # "fake returns" caused by either an exception being raised or a block being executed
      # that invoked `return` and caused other methods to return early
      unless nil.equal?(return_value)
        @ambiguous_exception_state    = false
        @ambiguous_block_return_state = false
      end

      seen << MethodCall.process(
        call_stack.pop.merge(
          return_value:              trace_event.return_value,
          in_ambiguous_raise:        ambiguous_exception_state,
          in_ambiguous_block_return: ambiguous_block_return_state
        )
      )
    end

    def process_raise
      call_stack.last[:error_raised] = true
      @ambiguous_exception_state = true
    end

    def process_block_return
      @ambiguous_block_return_state = true
    end

    def event_details(event)
      {
        scope:            event.defined_class.__send__(:singleton_class?) ? :class : :instance,
        selector:         event.method_id,
        namespace:        event.defined_class,
        example_location: RSpec.current_example.location,
        error_raised:     false
      }
    end

    def target?(klass)
      return false unless klass

      if klass.__send__(:singleton_class?)
        klass.to_s =~ /\A#{Regexp.quote("#<Class:#{namespace}")}/
      else
        klass.name && klass.name.start_with?(namespace.name)
      end
    end
  end # MethodTracer
end # Yardcheck
