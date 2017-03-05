# frozen_string_literal: true

require 'pathname'

require 'yard'

RSpec.describe Yardcheck::Documentation do
  def doc_for(title)
    selection = YardcheckSpec::YARDOCS.select { |doc| doc.title == title }
    fail "Unable to find doc with title #{title}" if selection.empty?
    described_class.new(selection)
  end

  def method_object(title)
    doc_for(title).method_objects.first
  end

  let(:namespace_add) { method_object('TestApp::Namespace#add') }

  it 'resolves constant' do
    expect(namespace_add.namespace).to be(TestApp::Namespace)
  end

  it 'resolves parameters' do
    expect(namespace_add.params).to eql(
      left: Yardcheck::Typedef.new([Integer]),
      right: Yardcheck::Typedef.new([Integer])
    )
  end

  it 'resolves return value' do
    expect(namespace_add.return_type).to eql(Yardcheck::Typedef.new([String]))
  end

  it 'labels instance scope' do
    expect(namespace_add.scope).to be(:instance)
  end

  it 'exposes the selector' do
    expect(namespace_add.selector).to be(:add)
  end

  it 'handles documented returns without types' do
    expect(method_object('TestApp::Namespace#return_tag_without_type').return_type)
      .to eql(Yardcheck::Typedef.new([]))
  end

  it 'handles returns with a literal nil' do
    expect(method_object('TestApp::Namespace#return_nil').return_type)
      .to eql(Yardcheck::Typedef.new([NilClass]))
  end

  it 'handles methods that return instance of the class' do
    expect(method_object('TestApp::Namespace#return_self').return_type)
      .to eql(Yardcheck::Typedef.new([TestApp::Namespace]))
  end

  it 'supports [undefined]' do
    expect(method_object('TestApp::Namespace#undefined_return').return_type)
      .to eql(Yardcheck::Typedef::Undefined.new)
  end

  it 'supports [Boolean]' do
    expect(method_object('TestApp::Namespace#bool_return').return_type)
      .to eql(Yardcheck::Typedef.new([TrueClass, FalseClass]))
  end

  it 'ignores documented params without names' do
    expect(method_object('TestApp::Namespace#param_without_name').params).to eql({})
  end
end
