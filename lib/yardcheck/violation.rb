module Yardcheck
  module Color
    private

    def color(code, text)
      "\e[#{code}m#{text}\e[0m"
    end

    def blue(text)
      color(34, text)
    end

    def red(text)
      color(31, text)
    end

    def yellow(text)
      color(33, text)
    end

    def grey(text)
      color(30, text)
    end
  end

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
        "#{color(33, '%<signature>s')} but observed " \
        "#{color(31, '%<observed_type>s')}"

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
        'Expected %<shorthand>s to receive %<signature>s ' \
        'for %<param_name>s but observed %<observed_type>s'

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
