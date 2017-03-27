# frozen_string_literal: true

RSpec.describe Yardcheck::ProcessedSource do
  context 'when method has a rescue with an embedded explicit return' do
    let(:source) { described_class.new(<<-RUBY) }
      def foo
        bar
      rescue SomeError
        return 2
      end
    RUBY

    it 'marks it as tracepoint bug candidate' do
      expect(source).to be_tracepoint_bug_candidate
    end
  end

  context 'when the method does not have a rescue or return' do
    let(:source) { described_class.new(<<-RUBY) }
      def foo
        bar
      end
    RUBY

    it 'is not a bug candidate' do
      expect(source).not_to be_tracepoint_bug_candidate
    end
  end

  context 'when the resbody contains an implicit return' do
    let(:source) { described_class.new(<<-RUBY) }
      def foo
        bar
      rescue
        baz
      end
    RUBY

    it 'is not a bug candidate' do
      expect(source).not_to be_tracepoint_bug_candidate
    end
  end
end
