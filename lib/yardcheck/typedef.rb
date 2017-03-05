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
        type == other || other < type
      end
    end

    def inspect
      types.join(' | ')
    end

    class Undefined < self
      include Concord.new

      def match?(_)
        true
      end

      def inspect
        'Undefined'
      end
    end # Undefined
  end # Typedef
end # Yardcheck
