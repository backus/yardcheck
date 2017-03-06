# frozen_string_literal: true

RSpec.describe Yardcheck::Runner do
  subject(:runner) { described_class.new(docs, observer) }

  let(:observer) { Yardcheck::SpecObserver.new(observed_events)         }
  let(:docs)     { Yardcheck::Documentation.new(YardcheckSpec::YARDOCS) }

  let(:observed_events) do
    [
      {
        type:     :call,
        scope:    :instance,
        method:   :add,
        'module': TestApp::Namespace,
        params:   { left: 'foo', right: 3 }
      },
      {
        type:         :return,
        scope:        :instance,
        method:       :add,
        'module':     TestApp::Namespace,
        return_value: 5
      },
      {
        type:     :call,
        scope:    :class,
        method:   :add,
        'module': TestApp::Namespace.singleton_class,
        params:   { left: 2, right: 3 }
      },
      {
        type:         :return,
        scope:        :class,
        method:       :add,
        'module':     TestApp::Namespace.singleton_class,
        return_value: 5
      }
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
end
