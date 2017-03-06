# frozen_string_literal: true

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

    def types
      method_calls
    end
    memoize :types

    private

    def method_calls
      events
        .group_by { |entry| entry.fetch_values(:module, :method, :scope) }
        .map { |_, observations| SessionObservations.new(observations) }
    end

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
        unique_events = events.map do |event|
          event.fetch_values(:module, :method, :scope)
        end.uniq

        fail 'wtf?' unless unique_events.one?

        unique_events.first
      end

      def param_values
        events_for(:call).map do |params:, **|
          params
        end
      end
      memoize :param_values

      def param_types
        events_for(:call).map do |params:, **|
          params.map { |key, value| [key, value.class] }.to_h
        end
      end
      memoize :param_types

      def return_values
        events_for(:return).map do |return_value:, **|
          return_value
        end.uniq
      end
      memoize :return_values

      def return_types
        events_for(:return).map do |return_value:, **|
          Object.instance_method(:class).bind(return_value).call
        end.uniq
      end
      memoize :return_types

      private

      def events_for(event_type)
        events.select { |type:, **| type.equal?(event_type) }
      end
    end
  end # SpecObserver
end # Yardcheck
