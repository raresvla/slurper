require 'rubygems'
require 'slurper'

describe Slurper do

  context "#create_stories" do
    let(:stories) { [YamlStory.new(:name => 'A story')] }
    let(:config) { {:tracker => 'jira'} }
    let(:slurper) { Slurper.new(config, stories) }
    let(:handler) { double('handler') }

    before do
      slurper.handlers = [handler]
    end

    it 'should error out if no handler can create the stories' do
      slurper.handlers = []
      expect { slurper.create_stories }.to raise_error
    end

    it "should detect the handler by checking the config" do
      handler.should_receive(:supports?).with(config).and_return(true)
      handler.should_receive(:configure!).and_return(true)
      handler.should_receive(:handle)

      slurper.create_stories
    end

    it "should call configure on the handler" do
      handler.should_receive(:supports?).with(config).and_return(true)
      handler.should_receive(:configure!).with(config)

      slurper.create_stories
    end

    it "should delegate to the proper handler" do
      jira = double
      jira.should_receive(:supports?).with(config).and_return(false)

      pivotal = double
      pivotal.should_receive(:supports?).with(config).and_return(true)
      pivotal.should_receive(:configure!).and_return(true)
      pivotal.should_receive(:handle).with(stories[0])

      slurper.handlers = [jira, pivotal]
      slurper.create_stories
    end

    it "should fail gracefully on handler exceptions" do
      handler.stub(:supports?).and_return(true)
      handler.should_receive(:configure!).and_return(true)
      handler.stub(:handle).and_raise('An error')

      expect { slurper.create_stories }.not_to raise_error
    end
  end

  context "Slurper#slurp" do
    it "should delegate one story to a handler" do
      story_file = File.join(File.dirname(__FILE__), "fixtures", "full_story.slurper")
      config_file = File.join(File.dirname(__FILE__), "fixtures", "slurper_config_pivotal.yml")

      handler = double
      handler.stub(:supports?).and_return true
      handler.stub(:configure!).and_return true
      handler.should_receive(:handle).once()

      Slurper.slurp(story_file, config_file, [handler], false)
    end
  end

  describe "#load_stories" do
    let(:file) { File.join(File.dirname(__FILE__), "fixtures", story_file) }
    let(:config) { {} }
    let(:stories) { Slurper.load_stories(file, config) }
    let(:story) { stories.first }

    context "default values" do
      let(:story_file) { 'whitespacey_story.slurper' }
      let(:config) { {'requested_by' => 'John Doe'} }

      it 'should load default values' do
        story.requested_by.should == 'John Doe'
      end
    end

    context "deals with leading/trailing whitespace" do
      let(:story_file) { 'whitespacey_story.slurper' }

      it "strips whitespace from the name" do
        story.name.should == "Profit"
      end
    end

    context "given values for all attributes" do
      let(:story_file) { 'full_story.slurper' }

      it "parses the name correctly" do
        story.name.should == 'Profit'
      end

      it "parses the label correctly" do
        story.labels.should == ['money','power','fame']
      end

      it "parses the story type correctly" do
        story.story_type.should == 'feature'
      end
    end

    context "given only a name" do
      let(:story) { stories.first }
      let(:story_file) { 'name_only.slurper' }

      it "should parse the name correctly" do
        story.name.should == "Profit"
      end

    end

    context "given empty attributes" do
      let(:story) { stories.first }
      let(:story_file) { 'empty_attributes.slurper' }

      it "should not set any name" do
        story.name.should be_nil
      end

      it "should not set any labels" do
        story.labels.should == []
      end
    end
  end

end
