# frozen_string_literal: true

module Yardcheck
  class Typedef
    class Parser
      include Concord.new(:namespace, :types), Adamantium

      def parse
        Typedef.parse(types.map(&method(:parse_type)).flatten.compact)
      end

      def parse_type(type)
        parsed_types = YARD::Tags::TypesExplainer::Parser.parse(type)
        parsed_types.map do |parsed_type|
          resolve_yard_type(parsed_type)
        end
      end

      def resolve_yard_type(yard_type)
        case yard_type
        when YARD::Tags::TypesExplainer::CollectionType
          Collection.new(*resolve_type(yard_type.name), yard_type.types.flat_map(&method(:resolve_yard_type)))
        when YARD::Tags::TypesExplainer::Type
          types = resolve_type(yard_type.name)
          case types
          when :undefined then Undefined.new
          when :ducktype  then Ducktype.parse(yard_type.name)
          else
            types.map { |type| Literal.new(type) }
          end
        else
          fail "wtf! #{yard_type}"
        end
      end

      def resolve_type(name)
        case name
        when 'nil' then   [Const.new(NilClass)]
        when 'true' then  [Const.new(TrueClass)]
        when 'false' then [Const.new(FalseClass)]
        when 'self' then [namespace_const]
        when 'undefined', 'void' then :undefined
        when 'Boolean', 'Bool' then [Const.new(TrueClass), Const.new(FalseClass)]
        when Ducktype::PATTERN then :ducktype
        else [tag_const(name)]
        end
      end

      def tag_const(name)
        Const.resolve(name, namespace_constant)
      end

      def namespace_const
        Const.resolve(namespace)
      end

      def namespace_constant
        namespace_const.constant
      end
      memoize :namespace_constant
    end # Parser
  end # Typedef
end # Yardcheck
