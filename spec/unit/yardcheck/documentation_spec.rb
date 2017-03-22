# frozen_string_literal: true

require 'pathname'

require 'yard'

RSpec.describe Yardcheck::Documentation do
  def yardocs_for(title)
    selection = YardcheckSpec::YARDOCS.select { |doc| doc.title == title }
    fail "Unable to find doc with title #{title}" if selection.empty?
    selection
  end

  def doc_for(title)
    described_class.new(yardocs_for(title))
  end

  def method_object(title)
    doc_for(title).method_objects.first
  end

  def literal(const)
    Yardcheck::Typedef::Literal.new(const)
  end

  def typedef(*members)
    Yardcheck::Typedef.new(members)
  end

  def const(constant)
    Yardcheck::Const.new(constant)
  end

  let(:namespace_add) { method_object('TestApp::Namespace#add') }

  it 'resolves constant' do
    expect(namespace_add.namespace).to eql(TestApp::Namespace)
  end

  it 'resolves parameters' do
    expect(namespace_add.params).to eql(
      left:  typedef(literal(const(Integer))),
      right: typedef(literal(const(Integer)))
    )
  end

  it 'resolves return value' do
    expect(namespace_add.return_type).to eql(typedef(literal(const(String))))
  end

  it 'labels instance scope' do
    expect(namespace_add.scope).to be(:instance)
  end

  it 'exposes the selector' do
    expect(namespace_add.selector).to be(:add)
  end

  it 'handles documented returns without types' do
    expect(method_object('TestApp::Namespace#return_tag_without_type').return_type)
      .to eql(typedef)
  end

  it 'handles returns with a literal nil' do
    expect(method_object('TestApp::Namespace#return_nil').return_type)
      .to eql(typedef(literal(const(NilClass))))
  end

  it 'handles methods that return instance of the class' do
    expect(method_object('TestApp::Namespace#return_self').return_type)
      .to eql(typedef(literal(const(TestApp::Namespace))))
  end

  it 'supports [undefined]' do
    expect(method_object('TestApp::Namespace#undefined_return').return_type)
      .to eql(typedef(Yardcheck::Typedef::Undefined.new))
  end

  it 'supports [Boolean]' do
    expect(method_object('TestApp::Namespace#bool_return').return_type)
      .to eql(typedef(literal(const(TrueClass)), literal(const(FalseClass))))
  end

  it 'supports [Array<String>]' do
    expect(method_object('TestApp::Namespace#array_return').return_type).to eql(
      typedef(Yardcheck::Typedef::Collection.new(const(Array), [literal(const(String))]))
    )
  end

  it 'supports multiple @return' do
    expect(method_object('TestApp::Namespace#multiple_returns').return_type)
      .to eql(typedef(literal(const(String)), literal(const(NilClass))))
  end

  it 'ignores documented params without names' do
    expect(method_object('TestApp::Namespace#param_without_name').params).to eql({})
  end

  it 'ignores invalid constant resolve' do
    expect(method_object('TestApp::Namespace#ignoring_invalid_types').params).to be_empty
  end

  it 'produces warnings for unresolvable params and returns' do
    method_object = method_object('TestApp::Namespace#ignoring_invalid_types')
    expect(method_object.warnings).to eql([
      Yardcheck::Warning.new(
        method_object,
        Yardcheck::Typedef::Parser.new('TestApp::Namespace', %w[What]).parse
      ),
      Yardcheck::Warning.new(
        method_object,
        Yardcheck::Typedef::Parser.new('TestApp::Namespace', %w[Wow]).parse
      )
    ])
  end

  it 'does not produce warnings for normal methods' do
    aggregate_failures do
      expect(method_object('TestApp::Namespace#add').warnings).to eql([])
      expect(method_object('TestApp::Namespace#undocumented').warnings).to eql([])
    end
  end

  it 'exposes source' do
    yardoc = yardocs_for('TestApp::Namespace#return_self').first

    allow(yardoc).to receive(:file).and_wrap_original do |method|
      File.join('./test_app', method.call).to_s
    end

    method_object = described_class::MethodObject.new(yardoc)
    expect(method_object.source).to eql(<<~RUBY.chomp)
    # @return [Namespace]
    def return_self
      self
    end
    RUBY
  end
end
