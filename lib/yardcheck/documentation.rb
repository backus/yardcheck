# frozen_string_literal: true

module Yardcheck
  class Documentation
    include Concord.new(:yardocs), Memoizable

    def self.load_yard
      # YARD doesn't write to .yardoc/ without this lock_for_writing and save
      YARD::Registry.lock_for_writing do
        YARD.parse(['lib/**/*.rb'], [], YARD::Logger::ERROR)
        YARD::Registry.save(true)
      end

      YARD::Registry.load!
    end

    def self.parse
      load_yard
      new(YARD::Registry.all(:method))
    end

    def types
      method_objects.reject do |method_object|
        method_object.unknown_param? || method_object.unknown_module? || method_object.unknown_return_value?
      end
    end
    memoize :types

    def method_objects
      yardocs.map { |yardoc| MethodObject.new(yardoc) }
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
end # Yardcheck
