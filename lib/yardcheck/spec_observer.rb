module Yardcheck
  class SpecObserver
    include Concord.new(:events), Memoizable

    def self.target?(namespace, scope)
      if scope.__send__(:singleton_class?)
        scope.to_s =~ /\A#{Regexp.quote("#<Class:#{namespace}")}/
      else
        scope.name && scope.name.start_with?(namespace)
      end
    end

    def self.run(rspec, namespace)
      events = []

      trace =
        TracePoint.new(:call, :return) do |tp|
          next unless target?(namespace, tp.defined_class)

          method_name     = tp.method_id
          observed_module = tp.defined_class
          parameter_names = observed_module.instance_method(method_name).parameters.map { |_, name| name }

          event = {
            type: tp.event,
            scope: tp.defined_class.__send__(:singleton_class?) ? :class : :instance,
            method: method_name,
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

          events << event
        end

      config_options = RSpec::Core::ConfigurationOptions.new(rspec)
      config = RSpec::Core::Configuration.new
      RSpec.configure do |config|
        config.around { |test| trace.enable(&test) }
      end
      runner = RSpec::Core::Runner.new(config_options)
      runner.setup($stderr, $stdout)

      runner.run_specs(RSpec.world.ordered_example_groups)

      new(events)
    end

    def self.fake_run(*)
      new([])
    end

    memoize def types
      events
        .group_by { |entry| entry.fetch_values(:module, :method, :scope) }
        .map do |_, observations|
          observations.reduce(:merge).select do |key, _|
            %i[module method params return_value scope].include?(key)
          end
        end.map do |params:, return_value:, **data|
          param_types = params.map { |key, value| [key, value.class] }.to_h
          return_value_type = return_value.class

          data.merge(params: param_types, return_value: return_value_type).sort.to_h
        end
    end
  end
end
