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

      def param(name)
        params.fetch(name)
      end

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

      def method_identifier
        [namespace, selector, scope]
      end

      def shorthand
        "#{namespace}##{selector}"
      end

      def source
        [documentation_source, yardoc.source].join("\n")
      end

      def location_pointer
        location.join(':')
      end

      private

      def documentation_source
        documentation_start = documentation_end = source_starting_line - 1

        until documentation_start == 0 || source_line_at(documentation_start) !~ /^\s*#/
          documentation_start -= 1
        end

        file_source[documentation_start..(documentation_end - 1)].join("\n")
      end

      def source_starting_line
        location.fetch(1)
      end

      def source_line_at(lineno)
        file_source[lineno - 1]
      end

      def file_source
        File.read(location.first).split("\n").map do |line|
          line.gsub(/^\s+/, '')
        end
      end
      memoize :file_source

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
