require 'rubygems'
require 'story'

describe YamlStory do
  context "#new" do
    it "should return a default value if it's set" do
      story = YamlStory.new({}, 'description' => 'Fill description', 'requested_by' => 'John Doe')

      expect(story.description).to eq 'Fill description'
      expect(story.requested_by).to eq 'John Doe'
    end
  end

  context "#requested_by" do
    it "should return nil when value is blank" do
      story = YamlStory.new('requested_by' => '')
      expect(story.requested_by).to be_nil
    end
  end

  context "#description" do
    it "when the description is blank" do
      story = YamlStory.new('description' => '', 'name' => 'test')
      expect(story.description).to be_nil
    end

    it "when there is no description given" do
      story = YamlStory.new
      expect(story.description).to be_nil
    end

    it "when it contains quotes" do
      desc = <<-STRING
        I have a "quote"
      STRING
      story = YamlStory.new('description' => desc)
      expect(story.description).to eq "I have a \"quote\"\n"
    end

    it "when it is full of whitespace" do
      desc = <<-STRING
        In order to do something
        As a role
        I want to click a thingy
      STRING
      story = YamlStory.new('description' => desc)
      expect(story.description).to eq "In order to do something\nAs a role\nI want to click a thingy\n"
    end

    it "when it contains acceptance criteria" do
      desc = <<-STRING
        In order to do something
        As a role
        I want to click a thingy

        Acceptance:
        - do the thing
        - don't forget the other thing
      STRING
      story = YamlStory.new('description' => desc)
      expect(story.description).to eq "In order to do something\nAs a role\nI want to click a thingy\n\nAcceptance:\n- do the thing\n- don't forget the other thing\n"
    end
  end

  context 'default attributes' do
    it 'uses the default if not given one' do
      story = YamlStory.new({}, {'requested_by' => 'Mr. Client'})
      expect(story.requested_by).to eq 'Mr. Client'
    end

    it 'uses the default if given a blank requested_by' do
      story = YamlStory.new({'requested_by' => ''}, {'requested_by' => 'Mr. Client'})
      expect(story.requested_by).to eq 'Mr. Client'
    end

    it 'uses the name given in the story file if there is one' do
      story = YamlStory.new({'requested_by' => 'Mr. Stakeholder'}, {'requested_by' => 'Mr. Client'})
      expect(story.requested_by).to eq 'Mr. Stakeholder'
    end
  end
end
