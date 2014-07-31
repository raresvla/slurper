# Simple value object for a story
# It's only concern is to store and format yaml data from stories
class YamlStory

  def initialize(attributes = {}, defaults = {})
    # delete empty values
    attributes.delete_if do |key, val|
      val == '' && defaults.key?(key)
    end
    @attributes = defaults.merge(attributes)
  end

  def labels
    (@attributes['labels'] || '').split(',').map(&:strip)
  end

  def description
    description = @attributes['description'] || ''
    if description == ''
      nil
    else
      description.gsub('  ', '').gsub(" \n", "\n")
    end
  end

  def [](key)
    raise "Attribute #{key} not defined" unless @attributes.key?(key.to_s)

    if respond_to?(key.to_sym)
      send(key.to_sym)
    else
      @attributes[key.to_s] == '' ? nil : @attributes[key.to_s]
    end
  end

  def []=(key, value)
    @attributes[key.to_s] = value
  end

  def method_missing(symbol)
    self[symbol]
  end

  def to_hash
    @attributes.keys.inject({}) do |hash, key|
      hash[key] = self[key]
      hash
    end
  end

  def yaml_description
    description = @attributes['description']
    if description.nil? || description.empty?
      ''
    else
      description.gsub(/^/, '  ')
    end
  end

  def to_yaml
    <<-yaml
==
story_type: #{story_type}
name: "#{name.gsub('"', "'")}"
description:
#{yaml_description}
labels: #{labels.join(', ')}
==
    yaml
  end

end
