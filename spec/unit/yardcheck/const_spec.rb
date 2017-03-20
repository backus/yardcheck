# frozen_string_literal: true

RSpec.describe Yardcheck::Const do
  before do
    stub_const('Foo', Module.new)

    module Foo
      module Bar
        module Baz
        end
      end
    end
  end

  it 'resolves top level constant' do
    expect(described_class.resolve('Foo')).to eql(described_class.new(Foo))
  end

  it 'resolves namespaced constant with qualified top level parent' do
    expect(described_class.resolve('Foo::Bar')).to eql(described_class.new(Foo::Bar))
  end

  it 'resolves nested constant from nested scope' do
    expect(described_class.resolve('Bar', Foo)).to eql(described_class.new(Foo::Bar))
  end

  it 'resolves top parent constant from scope of nested constant' do
    expect(described_class.resolve('Foo', Foo::Bar)).to eql(described_class.new(Foo))
  end

  it 'resolves nested constant form deeply nested scope' do
    expect(described_class.resolve('Foo::Bar', Foo::Bar::Baz)).to eql(described_class.new(Foo::Bar))
  end

  it 'resolves top level stdlib constant from scope of nested constant' do
    expect(described_class.resolve('String', Foo::Bar::Baz)).to eql(described_class.new(String))
  end

  it 'resolves the scope when given the scope name' do
    expect(described_class.resolve('Bar', Foo::Bar)).to eql(described_class.new(Foo::Bar))
  end

  it 'returns an invalid const object when given an unresolveable reference' do
    expect(described_class.resolve('What', Foo::Bar)).to eql(
      described_class::Invalid.new(Foo::Bar, 'What')
    )
  end
end
