# frozen_string_literal: true

require 'pathname'

require 'yard'

RSpec.describe Yardcheck::Documentation do
  def doc_for(title)
    described_class.new(YardcheckSpec::YARDOCS.select { |doc| doc.title == title })
  end

  def method_object(title)
    doc_for(title).method_objects.first
  end

  let(:namespace_add) { method_object('TestApp::Namespace#add') }

  it 'resolves constant' do
    expect(namespace_add.namespace).to be(TestApp::Namespace)
  end

  it 'resolves parameters' do
    expect(namespace_add.params).to eql(left: Integer, right: Integer)
  end

  it 'resolves return value' do
    expect(namespace_add.return_type).to be(String)
  end

  it 'labels instance scope' do
    expect(namespace_add.scope).to be(:instance)
  end

  it 'exposes the selector' do
    expect(namespace_add.selector).to be(:add)
  end

  it 'handles documented returns without types' do
    expect(method_object('TestApp::Namespace#return_tag_without_type').return_type).to be(nil)
  end

  it 'ignores documented params without names' do
    expect(method_object('TestApp::Namespace#param_without_name').params).to eql({})
  end
end
