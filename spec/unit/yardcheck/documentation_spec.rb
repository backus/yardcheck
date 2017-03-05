# frozen_string_literal: true

require 'pathname'

require 'yard'

RSpec.describe Yardcheck::Documentation do
  def doc_for(title)
    described_class.new(YardcheckSpec::YARDOCS.select { |doc| doc.title == title })
  end

  let(:namespace_add) { doc_for('TestApp::Namespace#add').method_objects.first }

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
end
