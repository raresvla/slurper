require 'yaml'
require 'story'

class Slurper
  attr_accessor :story_file, :stories, :handlers

  def self.dump(config_file, filter, handlers, reverse)
    config = self.load_config(config_file)
    slurper = new(config)
    slurper.handlers = handlers
    slurper.dump_stories(filter)
  end

  def self.slurp(story_file, config_file, handlers, reverse)
    config = self.load_config(config_file)

    stories = self.load_stories(story_file, config)
    stories.reverse! unless reverse

    slurper = new(config, stories)
    slurper.handlers = handlers
    slurper.create_stories
  end

  def initialize(config, stories=[])
    @config = config
    @stories = stories
    @handlers = []
  end

  def self.load_stories(story_file, defaults = {})
    stories = []
    yamlize_story_file(story_file).each do |story|
      begin
         story_hash = YAML.load(story)
         stories << story_hash if story_hash.is_a?(Hash)
      rescue
        puts 'Error encountered when trying to parse the following story'
        puts '-' * 10
        puts story
        puts '-' * 10
        return []
      end
    end
    stories.map { |story_hash| YamlStory.new(story_hash, defaults) }
  end

  def self.load_config(config_file)
    YAML.load_file(config_file)
  end

  def dump_stories(filter)
    handler.dump(filter) do |story|
      puts story.to_yaml
    end
  end

  def create_stories
    puts "Preparing to slurp #{stories.size} stories into #{handler.class.name}..."

    @stories.each_with_index do |story, index|
      puts "#{index+1}. #{story.name}"

      begin
        handler.handle(story) do |status, message|
          if status then
            puts "Success: #{message}"
          else
            puts "Failed: #{message}"
          end
        end

      rescue Exception => ex
        puts "Failed: #{ex.message}"
      end
    end
  end

  protected

  def handler
    return @handler if @handler

    config = @config

    error = "No handler found for the given configuration: #{config}"

    handler = @handlers.detect { |handler| handler.supports? config }

    raise error if not handler

    handler.configure! config

    @handler = handler
  end

  def self.yamlize_story_file(story_file)
    IO.read(story_file).
      gsub(/description:$/, 'description: |').
      gsub(/\t/, '  ').
      split(/==.*/)
  end

end
