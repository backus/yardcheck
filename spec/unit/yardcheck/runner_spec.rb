# frozen_string_literal: true

RSpec.describe Yardcheck::Runner do
  subject(:runner) { described_class.new(docs, observer) }

  let(:observer) { Yardcheck::SpecObserver.new(observed_events)         }
  let(:docs)     { Yardcheck::Documentation.new(YardcheckSpec::YARDOCS) }

  let(:observed_events) do
    [
      Yardcheck::MethodTracer::Event.new(
        scope:    :instance,
        method:   :add,
        'module': TestApp::Namespace,
        params:   { left: 'foo', right: 3 },
        return_value: 5
      ),
      Yardcheck::MethodTracer::Event.new(
        scope:    :class,
        method:   :add,
        'module': TestApp::Namespace.singleton_class,
        params:   { left: 2, right: 3 },
        return_value: 5
      )
    ]
  end

  it 'compares the spec observations against the documentation' do
    expect { runner.check }
      .to output(<<~OUTPUT).to_stderr
      Expected TestApp::Namespace#add to receive Integer for left but observed String
      Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum
      Expected TestApp::Namespace#add to return String but observed Fixnum
      OUTPUT
  end

  context 'when observing a properly used method documented with Enumerable<*>' do
    let(:observed_events) do
      [
        Yardcheck::MethodTracer::Event.new(
          scope:    :instance,
          method:   :enumerable_param,
          'module': TestApp::Namespace,
          params:   { list: %w[foo bar] },
          return_value: nil
        )
      ]
    end

    it 'accepts the usage' do
      expect { runner.check }.not_to output.to_stderr
    end
  end

  context 'when observing an improperly used method documented with Enumerable<*>' do
    let(:observed_events) do
      [
        Yardcheck::MethodTracer::Event.new(
          scope:    :instance,
          method:   :enumerable_param,
          'module': TestApp::Namespace,
          params:   { list: 'foo' },
          return_value: nil
        )
      ]
    end

    it 'accepts the usage' do
      expect { runner.check }.to output(<<~OUTPUT).to_stderr
      Expected TestApp::Namespace#enumerable_param to receive Enumerable<["Integer"]> for list but observed String
      OUTPUT
    end
  end
end
