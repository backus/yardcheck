# frozen_string_literal: true

module Yardcheck
  class Documentation
    class MethodObject
      include Concord.new(:yardoc), Adamantium::Flat

      def selector
        yardoc.name.to_sym
      end

      def namespace
        singleton? ? unscoped_namespace.singleton_class : unscoped_namespace
      end
      memoize :namespace

      def params
        tags(:param).map do |param_tag|
          param_name = param_tag.name.to_sym if param_tag.name
          [param_name, typedefs(param_tag)]
        end.select { |key, _| key }.to_h
      end

      def return_type
        return if tags(:return).empty?

        tags(:return).map(&method(:typedefs)).reduce(:+)
      end

      def singleton?
        scope == :class
      end

      def scope
        yardoc.scope
      end

      def location
        [yardoc.file, yardoc.line]
      end

      def unknown_param?
        params.any? { |(_name, owner)| owner.nil? }
      end

      def unknown_module?
        namespace.nil?
      end

      def unknown_return_value?
        return_type.nil?
      end

      def to_h
        {
          method:       selector,
          'module':     namespace,
          scope:        scope,
          params:       params,
          return_value: return_type,
          location:     location
        }
      end

      private

      def typedefs(tags)
        Typedef::Parser.new(qualified_namespace, tags.types.to_a).parse
      end

      def unscoped_namespace
        const(qualified_namespace)
      end
      memoize :unscoped_namespace

      def qualified_namespace
        yardoc.namespace.to_s
      end

      def tags(type)
        yardoc.tags(type)
      end

      def const(name)
        resolve(Object, name)
      end

      def resolve(receiver, name)
        receiver.const_get(name)
      rescue NameError
      end
    end # MethodObject
  end # Documentation
end # Yardcheck
