# frozen_string_literal: true

module Yardcheck
  class Runner
    include Concord.new(:documentation, :observations)

    def self.run(args)
      options = { rspec: 'spec' }

      parser =
        OptionParser.new do |opt|
          opt.on('--namespace NS', 'Namespace to check documentation for and watch methods calls for') do |arg|
            options[:namespace] = arg
          end

          opt.on('--include PATH', 'Path to add to load path') do |arg|
            options[:include] = arg
          end

          opt.on('--require LIB', 'Library to require') do |arg|
            options[:require] = arg
          end

          opt.on('--rspec ARGS', 'Arguments to give to rspec') do |arg|
            options[:rspec] = arg
          end
        end

      parser.parse(args)

      namespace, include_path, require_target, rspec = arguments = options.fetch_values(:namespace, :include, :require, :rspec)

      fail 'All arguments are required' if arguments.any?(&:nil?)

      $LOAD_PATH.unshift(include_path)
      require require_target

      rspec = rspec.split(' ')

      new(Yardcheck::Documentation.parse, Yardcheck::SpecObserver.run(rspec, namespace))
    end

    def check
      comparison = RuntimeComparison.new(documentation, observations)

      comparison.each_param do |documentation, observation, documented_params|
        documented_params.each do |name, typedef|
          check_param(
            typedef,
            observation,
            name,
            documentation
          )
        end
      end

      comparison.each_return do |documentation, observation, documented_return|
        observation.invalid_returns(documented_return) do |observed_return|
          warn "Expected #{documentation.shorthand} to return #{documented_return.signature} but observed #{observed_return.type}"
        end
      end
    end

    private

    def check_param(typedef, observation, name, documentation)
      observation.invalid_param_usage(name, typedef) do |observed_param|
        warn "Expected #{documentation.shorthand} to receive #{typedef.signature} for #{name} but observed #{observed_param.type}"
      end
    end

    class RuntimeComparison
      include Concord.new(:documentation, :spec_observation), Adamantium::Flat

      def each_param
        comparable_method_identifiers.map do |method_identifier|
          observation   = observation_for(method_identifier)
          documentation = documentation_for(method_identifier)

          yield(documentation, observation, documentation.params)
        end
      end

      def each_return
        comparable_method_identifiers.map do |method_identifier|
          observation   = observation_for(method_identifier)
          documentation = documentation_for(method_identifier)

          yield(documentation, observation, documentation.return_type)
        end
      end

      private

      def observation_for(identifier)
        observation_table.fetch(identifier)
      end

      def documentation_for(identifier)
        documentation_table.fetch(identifier)
      end

      def comparable_method_identifiers
        documentation_table.keys & observation_table.keys
      end
      memoize :comparable_method_identifiers

      def documentation_table
        table(documentation)
      end
      memoize :documentation_table

      def observation_table
        table(spec_observation)
      end
      memoize :observation_table

      def table(method_data_collection)
        method_data_collection.types.map { |item| [item.method_identifier, item] }.to_h
      end
    end
  end # Runner
end # Yardcheck
