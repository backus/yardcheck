module Yardcheck
  class Violation
    def warning
      indented_source = documentation.source.gsub(/^/, '    ')
      source = "\n#{CodeRay.encode(indented_source, :ruby, :terminal)}\n"

      "#{explanation}\n#{source}\n"
    end

    class Return < self
      include Concord.new(:documentation, :observation, :observed_value)

      def explanation
        shorthand     = documentation.shorthand
        signature     = documentation.return_type.signature
        observed_type = observed_value.type

        "Expected #{shorthand} to return #{signature} " \
        "but observed #{observed_type}"
      end
    end

    class Param < self
      include Anima.new(
        :documentation,
        :observation,
        :param_name,
        :observed_value
      )

      def explanation
        shorthand     = documentation.shorthand
        signature     = documentation.param(param_name).signature
        name          = param_name
        observed_type = observed_value.type

        "Expected #{shorthand} to receive #{signature} " \
        "for #{name} but observed #{observed_type}"
      end
    end
  end
end # Yardcheck
