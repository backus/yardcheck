# frozen_string_literal: true

module Yardcheck
  class MethodTracer
    include Concord.new(:namespace, :seen, :call_stack), Memoizable

    def initialize(namespace)
      super(namespace, [], [])

      # When an exception is raised it isn't clear when it has been eventually rescued.
      # We set `@current_exception` to `true` when we have observed an exception
      # and have not seen a non `nil` return.
      @current_exception = nil

      # A block passed from one method down to another method can trigger a return of the
      # originating method. This triggers a waterfall of `nil` returns because each method
      # shortcircuits. Similar to `current_exception` we need to also track jumps triggered
      # by block returns
      @block_jump = false
    end

    def trace(&block)
      tracer.enable(&block)
    end

    def events
      seen.freeze
    end

    private

    attr_reader :current_exception, :block_jump

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
      when :raise    then process_raise(trace_event)
      when :b_return then process_block_return
      end
    end

    def process_call(trace_event)
      # If we observe a method call then we are certainly no longer inside of a
      # bubbling up of early returns
      @block_jump = false

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
        @current_exception = nil
        @block_jump        = false
      end

      frame = call_stack.pop
      method_call =
        if @current_exception
          MethodCall::Raise.process(frame.merge(exception: @current_exception))
        elsif @block_jump
          MethodCall::Jump.process(frame)
        else
          MethodCall::Return.process(frame.merge(return_value: return_value))
        end

      seen << method_call
    end

    def process_raise(trace_event)
      @current_exception = trace_event.raised_exception
    end

    def process_block_return
      @block_jump = true
    end

    def event_details(event)
      {
        scope:            event.defined_class.__send__(:singleton_class?) ? :class : :instance,
        selector:         event.method_id,
        namespace:        event.defined_class,
        example_location: RSpec.current_example.location
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
