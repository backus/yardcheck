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
      method_objects.map do |method_object|
        {
          method:       method_object.selector,
          'module':     method_object.namespace,
          scope:        method_object.scope,
          params:       method_object.params,
          return_value: method_object.return_type
        }
      end.reject do |entry|
        entry[:params].any? { |(_name, owner)| owner.nil? } || entry[:module].nil? || entry[:return_value].nil?
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
        return unless (tag = tags(:return).first)

        typedefs(tag)
      end

      def singleton?
        scope == :class
      end

      def scope
        yardoc.scope
      end

      private

      def typedefs(tags)
        Typedef.parse(tags.types.to_a.map(&method(:resolve_type)).flatten.compact)
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

      def resolve_type(name)
        case name
        when 'nil' then [NilClass]
        when 'undefined' then [:undefined]
        when 'Boolean', 'Bool' then [TrueClass, FalseClass]
        else [tag_const(name)]
        end
      end

      def tag_const(name)
        if name.to_sym == yardoc.namespace.name
          unscoped_namespace
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
        qualified_namespace.split('::').reduce([]) do |namespaces, name|
          parent = namespaces.last || Object
          namespaces + [resolve(parent, name)]
        end.compact.reverse
      end
      memoize :nesting

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
