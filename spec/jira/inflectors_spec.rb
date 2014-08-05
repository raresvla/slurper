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

describe Jira::Inflectors do
  describe '.factory' do
    subject { described_class.factory(type, original) }

    %w(TextField FreeTextField URLField).each do |type|
      context "with #{type} data" do
        let(:type) { type }
        let(:original) { ' Anna has apples  ' }
        its(:value) { should == 'Anna has apples' }
      end
    end

    %w(GroupPicker UserPicker SingleVersionPicker SingleSelect).each do |type|
      context "with #{type} data" do
        let(:type) { type }
        let(:original) { 'something' }
        its(:value) { should == {name: 'something'} }
      end
    end

    %w(MultiUserPicker MultiGroupPicker MultiSelect).each do |type|
      context "with #{type} data" do
        let(:type) { type }
        let(:original) { %w(a b c) }
        its(:value) { should == [{name: 'a'}, {name: 'b'}, {name: 'c'}] }
      end
    end

    context 'with Labels' do
      let(:type) { 'Labels' }

      context 'when value is array' do
        let(:original) { ['Anna', 'has', 'a lot of apples'] }
        its(:value) { should == %w(Anna has a_lot_of_apples) }
      end

      context 'when value is a string' do
        let(:original) { 'Anna, has, a lot of apples' }
        its(:value) { should == %w(Anna has a_lot_of_apples) }
      end
    end

    context 'with SelectList data' do
      let(:type) { 'SelectList' }
      let(:original) { 'something' }
      its(:value) { should == {value: 'something'} }
    end

    context 'with ProjectPicker data' do
      let(:type) { 'ProjectPicker' }
      let(:original) { 'Some Project Name' }
      its(:value) { should == {key: 'Some Project Name'} }
    end

    context 'dynamic inflector' do
      context 'when is defined' do
        let(:type) { 'NumberField' }
        let(:original) { '12.33' }
        its(:value) { should == 12.33 }
      end

      context 'when is not found' do
        let(:type) { 'SomethingCrazy' }
        let(:original) { 'Anna has apples' }
        it 'should raise exception' do
          expect { subject }.to raise_exception
        end
      end
    end
  end
end
