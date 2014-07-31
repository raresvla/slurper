require 'rubygems'
require 'slurper'
require 'story'
require 'jira'

describe Jira::StoryMapper do
  let(:story) do
    YamlStory.new('project' => 'Test', 'name' => 'Story name', 'story_type' => 'Feature',
                  'description' => 'Story desc', 'labels' => 'a, b',
                  'reporter' => 'User', 'assignee' => 'A guy')
  end
  let(:mapper) { described_class.new }

  describe '#map' do
    subject { mapper.map(story) }

    context 'default mappings' do
      it do
        should == {
            :fields => {
                project: {key: 'Test'},
                summary: 'Story name',
                issuetype: {name: 'Feature'},
                description: 'Story desc',
                labels: %w(a b),
                reporter: {name: 'User'},
                assignee: {name: 'A guy'},
            }
        }
      end
    end

    context 'extra mappings' do
      before do
        mapper.configure!(:mappings => {
            test: {:type => 'TextField'},
            something: {:field_name => 'Cici', :type => 'TextField'}
        })
        story.tap do |s|
          s['test'] = 'Hello'
          s['something'] = 'World!'
        end
      end

      it do
        should == {
            :fields => {
                project: {key: 'Test'},
                summary: 'Story name',
                issuetype: {name: 'Feature'},
                description: 'Story desc',
                labels: %w(a b),
                reporter: {name: 'User'},
                assignee: {name: 'A guy'},
                test: 'Hello',
                Cici: 'World!'
            }
        }
      end
    end
  end
end

describe Jira::ApiConsumer do
  it 'should post with correctly configured the url' do
    good_response = double(success?: true, body: '{"id": 1, "key": "TEST-1", "self":"http://localhost:8090/rest/api/2/issue/1"}')

    api = described_class.new
    api.configure!('http://server', 'user', 'pass', '2')

    expect(api).to receive(:post).with('http://server/rest/api/2/issue/', 'json', kind_of(Hash)).and_return good_response

    api.create_issue(double(to_json: 'json'))

  end

  it 'should raise error if the issue was not saved' do
    bad_response = double(success?: false, status: 401)
    issue = double(to_json: 'json')

    api = described_class.new
    api.configure!('http://server', 'user', 'pass', '2')

    expect(api).to receive(:post).and_return(bad_response)
    expect { api.create_issue(issue) }.to raise_error Exception
  end

end

describe Jira::Handler do

  before do
    @jira = described_class.new
  end

  context '#supports' do
    it 'should support the jira config if tracker is given' do
      expect(@jira.supports?('tracker' => 'jira')).to be true
    end

    it 'should not support if tracker is missing' do
      expect(@jira.supports?({})).to be false
    end

    it 'should not support if tracker is anything else' do
      expect(@jira.supports?('tracker' => 'pivotal')).to be false
    end
  end

  context "#configure" do
    it 'should fail if a required field is missing' do
      expect {
        @jira.configure!(:project => 'a project').should be_false
      }.to raise_error 'Missing values for: password, url, username'
    end

    context 'good config provided' do
      before do
        required = [:username, :password, :project, :url]
        @raw_config = Hash[required.map { |v| [v, 'value'] }]
      end

      it 'should pass if the required fields are present' do
        config = @jira.configure! @raw_config
        expect(config[:username]).to eq 'value'
      end

      it 'should return the default api version' do
        config = @jira.configure! @raw_config
        expect(config[:api_version]).to eq 'latest'
      end

      it 'should overwrite the default api_version' do
        @raw_config[:api_version] = '2'
        config = @jira.configure! @raw_config
        expect(config[:api_version]).to eq '2'
      end
    end
  end

  context '#handle' do

    before do
      @config = {
          :project => 'AB',
          :username => 'user',
          :password => 'pass',
          :url => 'http://host'
      }
      @story = YamlStory.new(:description => 'description', :name => 'A story', :story_type => 'New Feature', :labels => 'a,b')
    end

    it 'should create a json issue using the api' do
      issue = double(to_json: 'json')
      mapper = double(map: issue, configure!: true)

      api = double()
      expect(api).to receive(:configure!).with('http://host', 'user', 'pass', 'latest')
      expect(api).to receive(:create_issue).with(issue).and_return([true, '{"id": 1, "key": "TEST-1", "self":"http://localhost:8090/rest/api/2/issue/1"}'])

      handler = described_class.new(mapper, api)
      handler.configure! @config
      handler.handle @story do |status, response|
        expect(status).to be true
        expect(response).to include('TEST-1')
      end
    end

  end

end
