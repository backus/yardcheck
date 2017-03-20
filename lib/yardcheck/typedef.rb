# frozen_string_literal: true

module Yardcheck
  class Typedef
    include Concord.new(:types)

    def self.parse(types)
      if types.include?(:undefined)
        fail 'Cannot combined [undefined] with other types' unless types.one?
        Undefined.new
      else
        new(types)
      end
    end

    def match?(other)
      types.any? do |type|
        type.match?(other)
      end
    end

    def signature
      types.to_a.map(&:signature).join(' | ')
    end

    def +(other)
      self.class.new((types + other.types).uniq)
    end

    def invalid_const?
      types.any?(&:invalid_const?)
    end

    class Literal < self
      include Concord.new(:const)

      def match?(value)
        value.is?(type_class)
      end

      def signature
        type_class.inspect
      end

      def type_class
        const.constant
      end

      def invalid_const?
        !const.valid?
      end
    end # Literal

    class Collection < self
      include Concord.new(:collection_const, :member_typedefs)

      def match?(other)
        Literal.new(collection_const).match?(other)
      end

      def signature
        "#{collection_class}<#{member_typedefs.map(&:signature)}>"
      end

      def collection_class
        collection_const.constant
      end

      def invalid_const?
        !collection_const.valid? || member_typedefs.any?(&:invalid_const?)
      end
    end # Collection

    class Undefined < self
      include Concord.new

      def match?(_)
        true
      end

      def signature
        'Undefined'
      end
    end # Undefined

    class Ducktype < self
      include Concord.new(:method_name)

      PATTERN = /\A\#(.+)\z/

      def self.parse(name)
        new(name[PATTERN, 1].to_sym)
      end

      def match?(other)
        other.duck_type?(method_name)
      end

      def signature
        "an object responding to ##{method_name}"
      end
    end # Ducktype
  end # Typedef
end # Yardcheck
