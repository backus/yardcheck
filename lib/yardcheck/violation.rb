module Yardcheck
  class Violation
    extend Color
    include Color

    def initialize(observation, test_locations = [observation.test_location])
      @observation    = observation
      @test_locations = test_locations
    end

    def warning
      indented_source = indent(observation.source_code)
      source = "\n#{CodeRay.encode(indented_source, :ruby, :terminal)}\n"

      location_hint = indent(grey("source: #{observation.source_location}"))
      test_lines    = test_locations.map { |l| "  - #{l}" }.join("\n")
      tests_block   = "tests:\n#{test_lines}"
      test_hint     = indent(grey(tests_block))

      "#{explanation}\n\n#{location_hint}\n#{test_hint}\n#{source}\n"
    end

    def combine(other)
      fail 'Cannot combine' unless combine_with?(other)

      with_tests(other.test_locations)
    end

    def combination_identifier
      combine_requirements.map(&method(:__send__))
    end

    attr_reader :test_locations

    private

    attr_reader :observation

    def combine_with?(other)
      combination_identifier == other.combination_identifier
    end

    def with_tests(other_test_locations)
      self.class.new(observation, test_locations + other_test_locations)
    end

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
      include Equalizer.new(:observation)

      FORMAT =
        "Expected #{blue('%<shorthand>s')} to return " \
        "#{yellow('%<signature>s')} but observed " \
        "#{red('%<observed_type>s')}"

      def initialize(observation, test_locations = [observation.test_location])
        super
      end

      def explanation
        format(
          FORMAT,
          shorthand: shorthand,
          signature: signature,
          observed_type: observed_type
        )
      end

      protected

      def observed_type
        observation.actual_return_type
      end

      private

      def combine_requirements
        %i[shorthand signature observed_type]
      end

      def expected_type
        observation.documented_return_type
      end
    end

    class Param < self
      include Equalizer.new(:name, :observation)

      def initialize(name, observation, test_locations = [observation.test_location])
        @name = name

        super(observation, test_locations)
      end

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
          test_value: observed_type
        )
      end

      def combine_with?(other)
        %i[shorthand signature observed_type]
      end

      private

      attr_reader :name

      def observed_type
        test_value.type
      end

      def combine_requirements
        %i[name shorthand signature observed_type]
      end

      def with_tests(other_test_locations)
        self.class.new(
          name,
          observation,
          test_locations + other_test_locations
        )
      end

      def test_value
        observation.observed_param(name)
      end

      def expected_type
        observation.documented_param(name)
      end
    end
  end
end # Yardcheck
