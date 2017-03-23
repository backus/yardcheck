# frozen_string_literal: true

RSpec.describe Yardcheck::Typedef::Parser do
  def parse(*types)
    described_class.new('TestApp::Namespace', types).parse
  end

  it 'resolves one normal constant' do
    expect(parse('Integer')).to eql(Yardcheck::Typedef.new([
      Yardcheck::Typedef::Literal.new(Yardcheck::Const.new(Integer))
    ]))
  end

  it 'resolves multiple constants' do
    expect(parse('Integer', 'String')).to eql(Yardcheck::Typedef.new([
      Yardcheck::Typedef::Literal.new(Yardcheck::Const.new(Integer)),
      Yardcheck::Typedef::Literal.new(Yardcheck::Const.new(String))
    ]))
  end

  it 'resolves child of namespace' do
    expect(parse('Child')).to eql(Yardcheck::Typedef.new([
      Yardcheck::Typedef::Literal.new(Yardcheck::Const.new(TestApp::Namespace::Child))
    ]))
  end

  it 'handles array of items' do
    expect(parse('Array<String>')).to eql(
      Yardcheck::Typedef.new([
        Yardcheck::Typedef::Collection.new(
          Yardcheck::Const.new(Array),
          [Yardcheck::Typedef::Literal.new(Yardcheck::Const.new(String))]
        )
      ])
    )
  end
end
