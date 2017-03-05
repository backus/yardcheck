# frozen_string_literal: true

require 'concord'
require 'yard'

require 'yardcheck/version'

module Yardcheck
  class Documentation
    include Concord.new(:method_objects)

    def self.parse
      # YARD doesn't write to .yardoc/ without this lock_for_writing and save
      YARD::Registry.lock_for_writing do
        YARD.parse(['lib/**/*.rb'], [])
        YARD::Registry.save(true)
      end

      YARD::Registry.load!

      new(YARD::Registry.all(:method))
    end

    def types
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
          'module':     owner,
          method:       method_name,
          params:       params,
          return_value: return_value
        }
      end
    end
  end # Documentation

  class SpecObserver
    def self.run
      new
    end

    def types
    end
  end
end # Yardcheck
