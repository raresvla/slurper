module Jira
  module Inflectors

    class BaseInflector
      def initialize(value)
        @value = value
      end

      def value
        @value
      end
    end

    class StringInflector < BaseInflector
      def initialize(value)
        super(value.to_s)
      end

      def value
        super.strip
      end
    end

    class NumberFieldInflector < BaseInflector
      def value
        @value.to_f
      end
    end

    class LabelInflector < StringInflector
      def value
        super.gsub(' ', '_')
      end
    end

    class IndexedValueInflector < BaseInflector
      def initialize(value, key=nil)
        super(value)
        if key.nil?
          key = :id if value.is_a?(Fixnum) or (value.is_a?(String) && value[/^[0-9]+$/])
        end
        @key = key || :value
      end

      def value
        {@key.to_sym => super}
      end
    end

    class CompositeInflector < BaseInflector
      def initialize(*inflectors)
        @inflectors = inflectors
      end

      def value
        @inflectors.map(&:value)
      end
    end

    def self.factory(type, value)
      case type.to_s
        when 'FreeTextField', 'TextField', 'URLField'
          StringInflector.new(value)
        when 'GroupPicker', 'UserPicker', 'SingleVersionPicker', 'SingleSelect'
          IndexedValueInflector.new(value, :name)
        when 'MultiUserPicker', 'MultiGroupPicker', 'MultiSelect'
          inner = ensure_list(value) do |value|
            value.map do |v|
              begin
                factory(type.sub('Multi', ''), v)
              rescue
                factory(type.sub('Multi', 'Single'), v)
              end
            end
          end
          CompositeInflector.new(*inner)
        when 'Labels'
          ensure_list(value) do |value|
            CompositeInflector.new(*(value.map { |v| LabelInflector.new(v) }))
          end
        when 'SelectList', 'Select'
          IndexedValueInflector.new(value, :value)
        when 'ProjectPicker'
          IndexedValueInflector.new(value, :key)
        else
          inflector = "#{type}Inflector".to_sym
          unless const_defined?(inflector)
            raise "Unrecognized field type \"#{type}\""
          end
          const_get(inflector).new(value)
      end
    end

    private

    def self.ensure_list(value)
      value = case value
                when String
                  value.split(',').map(&:strip)
                when Enumerable
                  value
                else
                  raise('Expected enumerable value')
              end
      yield value if block_given?
    end
  end
end
