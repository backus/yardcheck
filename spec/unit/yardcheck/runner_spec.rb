# frozen_string_literal: true

RSpec.describe Yardcheck::Runner do
  subject(:runner) { described_class.new(observations) }

  let(:observations) do
    [
      instance_double(
      Yardcheck::Observation, violations: [
        instance_double(Yardcheck::Violation, warning: %w[foo]),
        instance_double(Yardcheck::Violation, warning: %w[bar])
      ],
      ),
      instance_double(
        Yardcheck::Observation, violations: [
          instance_double(Yardcheck::Violation, warning: %w[baz])
        ],
      )
    ]
  end

  it 'outputs the warnings' do
    expect { runner.check }.to output("foo\nbar\nbaz\n").to_stderr
  end
end
