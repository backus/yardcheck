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
      TracePoint.new(:call, :return) do |tp|
        next unless target?(tp.defined_class)

        method_name     = tp.method_id
        observed_module = tp.defined_class
        parameter_names = observed_module.instance_method(method_name).parameters.map { |_, name| name }

        event = {
          type:     tp.event,
          scope:    tp.defined_class.__send__(:singleton_class?) ? :class : :instance,
          method:   method_name,
          'module': observed_module
        }

        case tp.event
        when :call
          scope  = tp.binding
          lvars  = scope.local_variables
          locals = lvars.map { |lvar| [lvar, scope.local_variable_get(lvar)] }.to_h
          event[:params] = locals.select { |lvar_name, _| parameter_names.include?(lvar_name) }
        when :return
          event[:return_value] = tp.return_value
        else
          fail
        end

        seen << event
      end
    end
    memoize :tracer

    def target?(klass)
      if klass.__send__(:singleton_class?)
        klass.to_s =~ /\A#{Regexp.quote("#<Class:#{namespace}")}/
      else
        klass.name && klass.name.start_with?(namespace.name)
      end
    end
  end
end
