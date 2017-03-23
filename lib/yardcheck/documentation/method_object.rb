# frozen_string_literal: true

module Yardcheck
  class Documentation
    class MethodObject
      include Concord.new(:yardoc), Adamantium::Flat

      def selector
        yardoc.name
      end

      def namespace
        singleton? ? unscoped_namespace.singleton_class : unscoped_namespace
      end
      memoize :namespace

      def params
        param_typedefs.select { |key, value| key && !value.invalid_const? }
      end
      memoize :params

      def return_type
        return_typedef unless return_typedef&.invalid_const?
      end

      def singleton?
        scope.equal?(:class)
      end

      def scope
        yardoc.scope
      end

      def location
        [yardoc.file, yardoc.line]
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

      def warnings
        param_warnings = param_typedefs.select { |_, typedef| typedef.invalid_const? }.values
        return_warning = return_typedef if return_typedef&.invalid_const?

        [*param_warnings, *return_warning].map { |warning| Warning.new(self, warning) }
      end

      private

      def return_typedef
        return_tag.map(&method(:typedefs)).reduce(:+)
      end
      memoize :return_typedef

      def return_tag
        tags(:return)
      end

      def param_typedefs
        tags(:param).map do |param_tag|
          param_name = param_tag.name.to_sym if param_tag.name
          [param_name, typedefs(param_tag)]
        end.to_h
      end
      memoize :param_typedefs

      def documentation_source
        file_source.documentation_above(source_starting_line)
      end

      def source_starting_line
        location.last
      end

      def file_source
        SourceLines.process(File.read(location.first))
      end
      memoize :file_source

      def typedefs(tags)
        Typedef::Parser.new(qualified_namespace, tags.types.to_a).parse
      end

      def unscoped_namespace
        Const.resolve(qualified_namespace).constant
      end
      memoize :unscoped_namespace

      def qualified_namespace
        yardoc.namespace.to_s
      end

      def tags(type)
        yardoc.tags(type)
      end
    end # MethodObject
  end # Documentation
end # Yardcheck
