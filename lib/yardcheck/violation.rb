module Yardcheck
  class Violation
    extend Color
    include Color

    def warning
      indented_source = indent(documentation.source)
      source = "\n#{CodeRay.encode(indented_source, :ruby, :terminal)}\n"

      location_hint = indent(color(30, "(at #{documentation.location_pointer})"))

      "#{explanation}\n\n#{location_hint}\n#{source}\n"
    end

    private

    def indent(string)
      string.gsub(/^/, '    ')
    end

    def shorthand
      documentation.shorthand
    end

    def signature
      expected_type.signature
    end

    def observed_type
      observed_value.type
    end

    class Return < self
      include Concord.new(:documentation, :observation, :observed_value)

      FORMAT =
        "Expected #{blue('%<shorthand>s')} to return " \
        "#{yellow('%<signature>s')} but observed " \
        "#{red('%<observed_type>s')}"

      def explanation
        format(
          FORMAT,
          shorthand: shorthand,
          signature: signature,
          observed_type: observed_type
        )
      end

      private

      def expected_type
        documentation.return_type
      end
    end

    class Param < self
      include Anima.new(
        :documentation,
        :observation,
        :param_name,
        :observed_value
      )

      FORMAT =
        "Expected #{blue('%<shorthand>s')} to " \
        "receive #{yellow('%<signature>s')} for #{blue('%<param_name>s')} " \
        "but observed #{red('%<observed_type>s')}"

      def explanation
        format(
          FORMAT,
          shorthand: shorthand,
          signature: signature,
          param_name: param_name,
          observed_type: observed_type
        )
      end

      private

      def expected_type
        documentation.param(param_name)
      end
    end
  end
end # Yardcheck
