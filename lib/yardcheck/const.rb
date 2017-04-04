# frozen_string_literal: true

module Yardcheck
  class Const
    include Concord::Public.new(:constant)

    SPECIAL_CASES = [
      Hash,
      Array
    ].map { |const| [const.name, const] }.to_h

    def self.resolve(constant_name, scope = Object)
      if scope.equal?(Object) && constant_name.empty?
        return new(Object)
      elsif scope.const_defined?(constant_name)
        return new(const_lookup(scope, constant_name))
      end

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

    def self.const_lookup(scope, name)
      SPECIAL_CASES.fetch(name) do
        scope.const_get(name) if scope.const_defined?(name)
      end
    end
    private_class_method :const_lookup

    def valid?
      true
    end

    class Invalid < self
      include Concord.new(:scope, :constant)

      public :constant

      def valid?
        false
      end
    end # Invalid
  end # Const
end # Yardcheck
