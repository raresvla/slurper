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
      expect(handler).to receive(:supports?).with(config).and_return(true)
      expect(handler).to receive(:configure!).and_return(true)
      expect(handler).to receive(:handle)

      slurper.create_stories
    end

    it "should call configure on the handler" do
      expect(handler).to receive(:supports?).with(config).and_return(true)
      expect(handler).to receive(:configure!).with(config)

      slurper.create_stories
    end

    it "should delegate to the proper handler" do
      jira = double
      expect(jira).to receive(:supports?).with(config).and_return(false)

      pivotal = double
      expect(pivotal).to receive(:supports?).with(config).and_return(true)
      expect(pivotal).to receive(:configure!).and_return(true)
      expect(pivotal).to receive(:handle).with(stories[0])

      slurper.handlers = [jira, pivotal]
      slurper.create_stories
    end

    it "should fail gracefully on handler exceptions" do
      allow(handler).to receive(:supports?).and_return(true)
      expect(handler).to receive(:configure!).and_return(true)
      allow(handler).to receive(:handle).and_raise('An error')

      expect { slurper.create_stories }.not_to raise_error
    end
  end

  context "Slurper#slurp" do
    it "should delegate one story to a handler" do
      story_file = File.join(File.dirname(__FILE__), "fixtures", "full_story.slurper")
      config_file = File.join(File.dirname(__FILE__), "fixtures", "slurper_config_pivotal.yml")

      handler = double
      allow(handler).to receive(:supports?).and_return true
      allow(handler).to receive(:configure!).and_return true
      expect(handler).to receive(:handle).once

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
        expect(story.requested_by).to eq 'John Doe'
      end
    end

    context "deals with leading/trailing whitespace" do
      let(:story_file) { 'whitespacey_story.slurper' }

      it "strips whitespace from the name" do
        expect(story.name).to eq "Profit"
      end
    end

    context "given values for all attributes" do
      let(:story_file) { 'full_story.slurper' }

      it "parses the name correctly" do
        expect(story.name).to eq 'Profit'
      end

      it "parses the label correctly" do
        expect(story.labels).to eq ['money','power','fame']
      end

      it "parses the story type correctly" do
        expect(story.story_type).to eq 'feature'
      end
    end

    context "given only a name" do
      let(:story) { stories.first }
      let(:story_file) { 'name_only.slurper' }

      it "should parse the name correctly" do
        expect(story.name).to eq "Profit"
      end

    end

    context "given empty attributes" do
      let(:story) { stories.first }
      let(:story_file) { 'empty_attributes.slurper' }

      it "should not set any name" do
        expect(story.name).to be_nil
      end

      it "should not set any labels" do
        expect(story.labels).to eq []
      end
    end
  end

end
