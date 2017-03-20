# frozen_string_literal: true

module Yardcheck
  class Const
    include Concord::Public.new(:constant)

    def self.resolve(constant_name, scope = Object)
      return new(scope.const_get(constant_name)) if scope.const_defined?(constant_name)

      parent = parent_namespace(scope)
      from_parent = resolve(constant_name, parent.constant) if parent.valid?
      from_parent && from_parent.valid? ? from_parent : Invalid.new(scope, constant_name)
    end

    def self.parent_namespace(scope)
      parent_name = scope.name.split('::').slice(0...-1).join('::')

      if parent_name.empty?
        Invalid.new(Object, parent_name)
      else
        resolve(parent_name)
      end
    end

    def valid?
      true
    end

    class Invalid < self
      include Concord.new(:scope, :constant)

      public :constant

      def valid?
        false
      end
    end
  end
end
