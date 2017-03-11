# frozen_string_literal: true

RSpec.describe Yardcheck::RuntimeComparison do
  subject(:comparison) { described_class.new(docs, observer) }

  let(:observer) { Yardcheck::SpecObserver.new(observed_events) }
  let(:docs)     { Yardcheck::Documentation.new(yardocs)        }

  let(:yardocs) do
    YardcheckSpec::YARDOCS.each do |yardoc|
      allow(yardoc).to receive(:file).and_wrap_original do |method|
        File.join('./test_app', method.call).to_s
      end
    end
  end

  let(:observed_events) do
    [
      Yardcheck::MethodCall.process(
        scope:    :instance,
        selector:   :add,
        namespace: TestApp::Namespace,
        params:   { left: 'foo', right: 3 },
        return_value: 5,
        example_location: RSpec.current_example.location
      ),
      Yardcheck::MethodCall.process(
        scope:    :class,
        selector:   :add,
        namespace: TestApp::Namespace.singleton_class,
        params:   { left: 2, right: 3 },
        return_value: 5,
        example_location: RSpec.current_example.location
      )
    ]
  end

  def remove_color(string)
    string.gsub(/\e\[(?:1\;)?\d+m/, '')
  end

  it 'compares the spec observations against the documentation' do
    expected = [
      <<~MSG,
      Expected TestApp::Namespace#add to receive Integer for left but observed String

          (at ./test_app/lib/test_app.rb:19)

          # Instance method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def add(left, right)
            left + right
          end

      MSG
      <<~MSG,
      Expected #<Class:TestApp::Namespace>#add to return String but observed Fixnum

          (at ./test_app/lib/test_app.rb:9)

          # Singleton method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def self.add(left, right)
            left + right
          end

      MSG
      <<~MSG
      Expected TestApp::Namespace#add to return String but observed Fixnum

          (at ./test_app/lib/test_app.rb:19)

          # Instance method with correct param definition and incorrect return
          #
          # @param left [Integer]
          # @param right [Integer]
          #
          # @return [String]
          def add(left, right)
            left + right
          end

      MSG
    ]

    expect(comparison.warnings.map(&method(:remove_color))).to eql(expected)
  end

end
