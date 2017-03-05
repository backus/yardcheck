# frozen_string_literal: true

require 'concord'
require 'yard'
require 'rspec'

require 'yardcheck/version'

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

          opt.on('--include PATH',   'Path to add to load path') do |arg|
            options[:include] = arg
          end

          opt.on('--require LIB',   'Library to require') do |arg|
            options[:require] = arg
          end

          opt.on('--rspec ARGS',     'Arguments to give to rspec') do |arg|
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
        entry = union[observed_type.fetch_values(:module, :method, :scope)] ||= {}
        entry[:observation] = observed_type
      end

      union.select! { |_, value| value.key?(:documentation) && value.key?(:observation) }

      union.each do |(mod, method_name), entry|
        documentation = entry.fetch(:documentation)
        observation   = entry.fetch(:observation)

        documented_params, documented_return = documentation.fetch_values(:params, :return_value)
        observed_params, observed_return     = observation.fetch_values(:params, :return_value)

        unless observed_return == documented_return || observed_return < documented_return
          warn "Expected #{mod}##{method_name} to return #{documented_return} but observed #{observed_return}"
        end
      end
    end
  end

  class Documentation
    include Concord.new(:method_objects), Memoizable

    def self.parse
      # YARD doesn't write to .yardoc/ without this lock_for_writing and save
      YARD::Registry.lock_for_writing do
        YARD.parse(['lib/**/*.rb'], [])
        YARD::Registry.save(true)
      end

      YARD::Registry.load!

      new(YARD::Registry.all(:method))
    end

    memoize def types
      method_objects.map do |method_object|
        param_tags       = method_object.tags(:param)
        return_value_tag = method_object.tags(:return).first
        owner_name       = method_object.namespace.to_s
        method_name      = method_object.name.to_sym

        fail 'I am not ready for this yet!' unless owner_name

        params =
          param_tags.map do |param_tag|
            fail 'I am not ready for multiple param types!' unless param_tag.types.one?
            [param_tag.name.to_sym, const(param_tag.types.first)]
          end

        fail 'I am not ready for multiple return types!' if return_value_tag && return_value_tag.types.to_a.size > 1
        return_value = const(return_value_tag.types.to_a.first) if return_value_tag

        owner = const(owner_name)
        owner = owner.singleton_class if method_object.scope == :class

        {
          method:       method_name,
          'module':     owner,
          scope:        method_object.scope,
          params:       params.to_h,
          return_value: return_value
        }
      end.reject do |entry|
        entry[:params].any? { |(_name, owner)| owner.nil? } || entry[:module].nil? || entry[:return_value].nil?
      end
    end

    private

    def const(name)
      return if name.nil?

      begin
        Object.const_get(name)
      rescue NameError
      end
    end
  end # Documentation

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

      trace.enable do
        RSpec::Core::Runner.run(rspec)
      end

      new(events)
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
end # Yardcheck
