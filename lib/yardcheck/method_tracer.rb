# frozen_string_literal: true

module Yardcheck
  class MethodTracer
    include Concord.new(:namespace, :seen), Memoizable

    def initialize(namespace)
      super(namespace, [])
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
        process(event) if target?(event.defined_class)
      end
    end
    memoize :tracer

    def process(trace_event)
      event =
        case trace_event.event
        when :call   then process_call(trace_event)
        when :return then process_return(trace_event)
        end

      seen << event
    end

    def process_call(trace_event)
      parameter_names =
        trace_event
          .defined_class
          .instance_method(trace_event.method_id)
          .parameters.map { |_, name| name }

      scope  = trace_event.binding
      lvars  = scope.local_variables
      locals = lvars.map { |lvar| [lvar, scope.local_variable_get(lvar)] }.to_h
      params = locals.select { |lvar_name, _| parameter_names.include?(lvar_name) }

      event_details(trace_event).update(params: params)
    end

    def process_return(trace_event)
      event_details(trace_event).update(return_value: trace_event.return_value)
    end

    def event_details(event)
      {
        type:     event.event,
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
  end
end
