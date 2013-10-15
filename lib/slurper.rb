require 'yaml'
require 'story'
YAML::ENGINE.yamler='syck' if RUBY_VERSION > '1.9'

class Slurper

  attr_accessor :story_file, :stories, :handlers

  def self.slurp(story_file, config_file, handlers, reverse)
    config = self.load_config(config_file)

    stories = self.load_stories(story_file, config)
    stories.reverse! unless reverse

    slurper = new(stories, config)
    slurper.handlers = handlers
    slurper.create_stories
  end

  def initialize(stories, config)
    @stories = stories
    @config = config
    @handlers = []
  end

  def self.load_stories(story_file, defaults = {})
    stories = YAML.load yamlize_story_file(story_file)
    stories.map { |story_hash| YamlStory.new(story_hash, defaults) }
  end

  def self.load_config(config_file)
    YAML.load_file(config_file).with_indifferent_access
  end

  def create_stories
    config = @config

    error = "No handler found for the given configuration: #{config}"

    handlers = @handlers.find_all { |handler| handler.supports(config) }

    raise error if handlers.length == 0

    handlers.each { |handler|
      puts "Preparing to slurp #{stories.size} stories into #{handler.class.name}..."

      handler.configure(config)

      @stories.each_with_index { |story, index|
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
      }
    }
  end

  protected

  def self.yamlize_story_file(story_file)
    IO.read(story_file).
      gsub(/^/, '    ').
      gsub(/    ==.*/, "- \n").
      gsub(/    description:$/, '    description: |')
  end

end
