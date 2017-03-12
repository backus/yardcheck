module Yardcheck
  class Violation
    extend Color
    include Color

    def warning
      indented_source = indent(observation.source_code)
      source = "\n#{CodeRay.encode(indented_source, :ruby, :terminal)}\n"

      location_hint = indent(grey("source: #{observation.source_location}"))
      test_hint     = indent(grey("test:   #{observation.test_location}"))

      "#{explanation}\n\n#{location_hint}\n#{test_hint}\n#{source}\n"
    end

    private

    def indent(string)
      string.gsub(/^/, '    ')
    end

    def shorthand
      observation.method_shorthand
    end

    def signature
      expected_type.signature
    end

    def observed_type
      observed_value.type
    end

    class Return < self
      include Concord.new(:observation)

      FORMAT =
        "Expected #{blue('%<shorthand>s')} to return " \
        "#{yellow('%<signature>s')} but observed " \
        "#{red('%<observed_type>s')}"

      def explanation
        format(
          FORMAT,
          shorthand: shorthand,
          signature: signature,
          observed_type: observation.actual_return_type
        )
      end

      private

      def expected_type
        observation.documented_return_type
      end
    end

    class Param < self
      include Concord.new(:name, :observation)

      FORMAT =
        "Expected #{blue('%<shorthand>s')} to " \
        "receive #{yellow('%<signature>s')} for #{blue('%<name>s')} " \
        "but observed #{red('%<test_value>s')}"

      def explanation
        format(
          FORMAT,
          shorthand: shorthand,
          signature: signature,
          name: name,
          test_value: test_value.type
        )
      end

      private

      def test_value
        observation.observed_param(name)
      end

      def expected_type
        observation.documented_param(name)
      end
    end
  end
end # Yardcheck
