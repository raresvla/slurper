require 'rubygems'
require 'spec'
require 'slurper'

describe Slurper do

  context "#create_stories" do
    before do
      @stories = [YamlStory.new(:name => 'A story')]
      @config = {:tracker => 'jira'}
      @slurper = Slurper.new(@stories, @config)
    end

    it "should error out if not handler can create the stories" do
      expect { @slurper.create_stories }.to raise_error
    end

    it "should detect the handler by checking the config" do
      handler = double('handler')
      handler.should_receive(:supports).with(@config).and_return(true)
      handler.should_receive(:configure).and_return(true)
      handler.should_receive(:handle)

      @slurper.handlers << handler

      @slurper.create_stories
    end

    it "should call configure on the handler" do
      handler = double
      handler.should_receive(:supports).with(@config).and_return(true)
      handler.should_receive(:configure).with(@config)

      @slurper.handlers << handler

      @slurper.create_stories
    end

    it "should delegate to the proper handler" do
      jira = double
      jira.should_receive(:supports).and_return(false)

      pivotal = double
      pivotal.should_receive(:supports).and_return(true)
      pivotal.should_receive(:configure).and_return(true)
      pivotal.should_receive(:handle).with(@stories[0])

      @slurper.handlers += [jira, pivotal]
      @slurper.create_stories
    end

    it "should fail gracefully on handler exceptions" do
      handler = double
      handler.stub(:supports).and_return(true)
      handler.should_receive(:configure).and_return(true)
      handler.stub(:handle).and_raise('An error')

      @slurper.handlers << handler
      expect { @slurper.create_stories }.should_not raise_error
    end
  end

  context "Slurper#slurp" do
    it "should delegate one story to a handler" do
      story_file = File.join(File.dirname(__FILE__), "fixtures", "full_story.slurper")
      config_file = File.join(File.dirname(__FILE__), "fixtures", "slurper_config_pivotal.yml")

      handler = double
      handler.stub(:supports).and_return true
      handler.stub(:configure).and_return true
      handler.should_receive(:handle).once()

      Slurper.slurp(story_file, config_file, [handler], false)
    end
  end

  context "#load_stories" do
    file = File.join(File.dirname(__FILE__), "fixtures", "whitespacey_story.slurper")
    config = {:requested_by => 'John Doe'}
    stories = Slurper.load_stories file, config

    stories.first.requested_by.should == 'John Doe'
  end

  context "deals with leading/trailing whitespace" do
    before do
      stories = Slurper.load_stories File.join(File.dirname(__FILE__), "fixtures", "whitespacey_story.slurper")
      @story = stories.first
    end

    it "strips whitespace from the name" do
      @story.name.should == "Profit"
    end
  end

  context "given values for all attributes" do
    before do
      stories = Slurper.load_stories File.join(File.dirname(__FILE__), "fixtures", "full_story.slurper")
      @story = stories.first
    end

    it "parses the name correctly" do
      @story.name.should == "Profit"
    end

    it "parses the label correctly" do
      @story.labels.should == "money,power,fame"
    end

    it "parses the story type correctly" do
      @story.story_type.should == "feature"
    end
  end

  context "given only a name" do
    before do
      stories = Slurper.load_stories File.join(File.dirname(__FILE__), "fixtures", "name_only.slurper")
      @story = stories.first
    end

    it "should parse the name correctly" do
      @story.name.should == "Profit"
    end

  end

  context "given empty attributes" do
    before do
      stories = Slurper.load_stories File.join(File.dirname(__FILE__), "fixtures", "empty_attributes.slurper")
      @story = stories.first
    end

    it "should not set any name" do
      @story.name.should be_nil
    end

    it "should not set any labels" do
      @story.labels.should be_nil
    end
  end

end
