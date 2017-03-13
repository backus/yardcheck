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
        when 'nil' then [NilClass]
        when 'true' then [TrueClass]
        when 'false' then [FalseClass]
        when 'self' then [namespace_constant]
        when 'undefined', 'void' then :undefined
        when 'Boolean', 'Bool' then [TrueClass, FalseClass]
        when Ducktype::PATTERN then :ducktype
        else [tag_const(name)]
        end
      end

      def tag_const(name)
        if namespace.end_with?(name)
          namespace_constant
        else
          from_root = const(name)
          from_root ? from_root : resolve_via_nesting(name)
        end
      end

      def resolve_via_nesting(name)
        nesting.each do |constant_scope|
          resolution = resolve(constant_scope, name)
          return resolution if resolution
        end

        nil
      end

      def nesting
        namespace.split('::').reduce([]) do |namespaces, name|
          parent = namespaces.last || Object
          namespaces + [resolve(parent, name)]
        end.compact.reverse
      end
      memoize :nesting

      def namespace_constant
        const(namespace)
      end
      memoize :namespace_constant

      def const(name)
        resolve(Object, name)
      end

      def resolve(receiver, name)
        receiver.const_get(name)
      rescue NameError
      end
    end # Parser
  end # Typedef
end # Yardcheck
