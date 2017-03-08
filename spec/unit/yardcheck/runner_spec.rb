# frozen_string_literal: true

RSpec.describe Yardcheck::Runner do
  subject(:runner) { described_class.new(fake_comparison) }

  let(:fake_comparison) do
    instance_double(
      Yardcheck::RuntimeComparison,
      warnings: %w[foo bar baz]
    )
  end

  it 'outputs the warnings' do
    expect { runner.check }.to output("foo\nbar\nbaz\n").to_stderr
  end
end
