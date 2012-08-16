require 'spec_helper'

describe Mutant::Context::Scope, '.build' do
  subject { described_class.build(constant, path) }

  let(:object)  { described_class }
  let(:context) { mock('Context') }
  let(:path)    { mock('Path')    }

  context 'when constant is a module' do
    let(:constant) { Module.new }

    it { should be_kind_of(described_class::Module) }
  end

  context 'when constant is a class' do
    let(:constant) { Class.new }

    it { should be_kind_of(described_class::Class) }
  end

  context 'when constant is not a class nor a module' do
    let(:constant) { Object.new }

    it 'should raise error' do
      expect { subject }.to raise_error(ArgumentError, 'Can only build mutation scope from class or module got: Object')
    end
  end
end