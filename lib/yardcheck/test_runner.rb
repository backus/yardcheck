module Yardcheck
  class TestRunner
    include Concord.new(:arguments)

    def wrap_test(wrapper)
      RSpec.configure do |config|
        config.around do |test|
          wrapper.call(&test)
        end
      end
    end

    def run
      runner.run_specs(RSpec.world.ordered_example_groups)
    end

    private

    def runner
      RSpec::Core::Runner.new(RSpec::Core::ConfigurationOptions.new(arguments)).tap do |runner|
        runner.setup($stderr, $stdout)
      end
    end
  end
end
