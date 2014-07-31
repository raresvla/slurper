require 'rspec/its'
require 'jira/inflectors'

describe Jira::Inflectors::StringInflector do

  subject { described_class.new(original) }

  context 'with string value' do
    let(:original) { 'Cici' }
    its(:value) { should == 'Cici' }
  end

  context 'with other value' do
    let(:original) { ['a'] }
    its(:value) { should == '["a"]' }
  end

end

describe Jira::Inflectors::NumberFieldInflector do

  subject { described_class.new(original) }

  context 'with string value' do
    let(:original) { '1.99' }
    its(:value) { should == 1.99 }
  end

  context 'with numeric value' do
    let(:original) { 1.99 }
    its(:value) { should == 1.99 }
  end

end

describe Jira::Inflectors::LabelInflector do

  subject { described_class.new(original) }

  let(:original) { 'anna has  green apples' }
  its(:value) { should == 'anna_has__green_apples' }

end

describe Jira::Inflectors::IndexedValueInflector do

  subject { described_class.new(original, key) }

  context 'with undefined key' do
    let(:key) { nil }

    context 'when value is numeric' do
      let(:original) { '1234' }
      its(:value) { should == {id: '1234'} }
    end

    context 'when value is a number' do
      let(:original) { 1234 }
      its(:value) { should == {id: 1234} }
    end

    context 'defaults key to :value' do
      let(:original) { 1234.10 }
      its(:value) { should == {value: 1234.10} }
    end
  end

  context 'with specified key' do
    let(:key) { 'testing' }
    let(:original) { 'something' }

    its(:value) { should == {testing: 'something'} }
  end

end

describe Jira::Inflectors::CompositeInflector do

  context 'with one inflector' do
    subject { described_class.new(Jira::Inflectors::StringInflector.new('test')) }
    its(:value) { should == ['test'] }
  end

  context 'with multiple inflectors' do
    subject do
      described_class.new(
          Jira::Inflectors::StringInflector.new('test'),
          Jira::Inflectors::IndexedValueInflector.new('testing', 'cici')
      )
    end
    its(:value) { should == ['test', {cici: 'testing'}] }
  end

end
