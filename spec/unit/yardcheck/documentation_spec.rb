# frozen_string_literal: true

require 'pathname'

require 'yard'

RSpec.describe Yardcheck::Documentation do
  def doc_for(title)
    described_class.new(YardcheckSpec::YARDOCS.select { |doc| doc.title == title })
  end

  let(:namespace_add) { doc_for('TestApp::Namespace#add').types.first }

  it 'resolves constant' do
    expect(namespace_add.namespace).to be(TestApp::Namespace)
  end

  it 'resolves parameters' do
    expect(namespace_add.params).to eql(left: Integer, right: Integer)
  end
end
