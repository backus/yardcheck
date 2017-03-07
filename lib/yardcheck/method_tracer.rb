# frozen_string_literal: true

module Yardcheck

  class MethodTracer
    include Concord.new(:namespace, :seen, :call_stack), Memoizable

    def initialize(namespace)
      super(namespace, [], [])
    end

    def trace(&block)
      tracer.enable(&block)
    end

    def events
      seen.freeze
    end

    private

    def tracer
      TracePoint.new(:call, :return) do |event|
        tracer.disable do
          process(event) if target?(event.defined_class)
        end
      end
    end
    memoize :tracer

    def process(trace_event)
      case trace_event.event
      when :call   then process_call(trace_event)
      when :return then process_return(trace_event)
      end
    end

    def process_call(trace_event)
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
      seen << Event.new(call_stack.pop.merge(return_value: trace_event.return_value))
    end

    def event_details(event)
      {
        scope:    event.defined_class.__send__(:singleton_class?) ? :class : :instance,
        method:   event.method_id,
        'module': event.defined_class
      }
    end

    def target?(klass)
      if klass.__send__(:singleton_class?)
        klass.to_s =~ /\A#{Regexp.quote("#<Class:#{namespace}")}/
      else
        klass.name && klass.name.start_with?(namespace.name)
      end
    end

    class Event
      include Anima.new(:scope, :method, :module, :params, :return_value)

      def method_identifier
        [self.module, self.method, scope]
      end
    end
  end
end
