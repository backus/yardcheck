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
      union = {}

      documentation.types.each do |documented_type|
        entry = union[documented_type.fetch_values(:module, :method, :scope)] = {}
        entry[:documentation] = documented_type
      end

      observations.types.each do |observed_type|
        entry = union[observed_type.to_h.fetch_values(:module, :method, :scope)] ||= {}
        entry[:observation] = observed_type
      end

      union.select! { |_, value| value.key?(:documentation) && value.key?(:observation) }

      union.each do |(mod, method_name), entry|
        documentation = entry.fetch(:documentation)
        observation   = entry.fetch(:observation)

        documented_params, documented_return = documentation.fetch_values(:params, :return_value)
        observed_params, observed_return     = observation.param_types, observation.return_value_type

        documented_params.each do |name, typedef|
          check_param(typedef, observed_params, documented_params, name, mod, method_name, documentation.fetch(:location))
        end

        unless documented_return.match?(observed_return)
          warn "Expected #{mod}##{method_name} to return #{documented_return.signature} but observed #{observed_return}"
        end
      end
    end

    def check_param(typedef, observed_params, documented_params, name, mod, method_name, loc) # jesus christ
      observed_param =
        observed_params.fetch(name) do
          warn "Expected to find param #{name} for #{mod}##{method_name} at #{loc}"
          return
        end

      unless typedef.match?(observed_param)
        warn "Expected #{mod}##{method_name} to receive #{typedef.signature} for #{name} but observed #{observed_param}"
      end
    end
  end # Runner
end # Yardcheck
