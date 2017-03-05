# frozen_string_literal: true

require 'concord'
require 'yard'
require 'rspec'

require 'yardcheck/version'

module Yardcheck
  class Runner
    include Concord.new(:documentation, :observations)

    def self.run
      new(Yardcheck::Documentation.parse, Yardcheck::SpecObserver.run)
    end

    def check
      union = {}

      documentation.types.each do |documented_type|
        entry = union[documented_type.fetch_values(:module, :method)] = {}
        entry[:documentation] = documented_type
      end

      observations.types.each do |observed_type|
        entry = union[observed_type.fetch_values(:module, :method)] ||= {}
        entry[:observation] = observed_type
      end

      union.each do |(mod, method_name), entry|
        documentation = entry.fetch(:documentation)
        observation   = entry.fetch(:observation)

        documented_params, documented_return = documentation.fetch_values(:params, :return_value)
        observed_params, observed_return     = observation.fetch_values(:params, :return_value)

        p observed_return
        p documented_return
        unless observed_return === documented_return
          fail "Expected #{mod}#{method_name} to return #{documented_return} but observed #{observed_return}"
        end
      end

      p union
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
        fail 'I am not ready for class methods!' unless method_object.scope == :instance

        param_tags       = method_object.tags(:param)
        return_value_tag = method_object.tags(:return).first
        owner_name       = method_object.namespace.name
        method_name      = method_object.name.to_sym

        fail 'I am not ready for this yet!' unless param_tags.size == 2 && return_value_tag && owner_name

        params =
          param_tags.map do |param_tag|
            fail 'I am not ready for multiple param types!' unless param_tag.types.one?
            [param_tag.name.to_sym, Object.const_get(param_tag.types.first)]
          end

        fail 'I am not ready for multiple return types!' unless return_value_tag.types.one?
        return_value = Object.const_get(return_value_tag.types.first)

        owner = Object.const_get(owner_name)

        {
          method:       method_name,
          'module':     owner,
          params:       params.to_h,
          return_value: return_value
        }
      end
    end
  end # Documentation

  class SpecObserver
    include Concord.new(:events), Memoizable

    def self.run
      events = []

      trace =
        TracePoint.new(:call, :return) do |tp|
          next unless tp.defined_class.name && tp.defined_class.name.start_with?('TestApp')


          method_name     = tp.method_id
          observed_module = tp.defined_class
          parameter_names = observed_module.instance_method(method_name).parameters.map { |_, name| name }

          event = {
            type: tp.event,
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
        RSpec::Core::Runner.run(['spec'])
      end

      new(events)
    end

    memoize def types
      events
        .group_by { |entry| entry.fetch_values(:module, :method) }
        .map do |_, observations|
          observations.reduce(:merge).select do |key, _|
            %i[module method params return_value].include?(key)
          end
        end.map do |params:, return_value:, **data|
          param_types = params.map { |key, value| [key, value.class] }.to_h
          return_value_type = return_value.class

          data.merge(params: param_types, return_value: return_value_type).sort.to_h
        end
    end
  end
end # Yardcheck
