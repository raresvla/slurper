require 'rubygems'
require 'slurper'
require 'story'
require 'jira'

describe JiraStoryMapper do
  before do
    @story = YamlStory.new('name' => 'Story name', 'story_type' => 'Feature',
                           'description' => 'Story desc', 'labels' => 'a, b')
    @mapper = JiraStoryMapper.new
  end

  it 'should take the project key from config' do
    result = @mapper.map(@story, 'AB')
    expect(result[:fields][:project][:key]).to eq 'AB'
  end

  it 'should set the issuetype field with the story_type' do
    result = @mapper.map(@story, 'AB')
    expect(result[:fields][:issuetype][:name]).to eq 'Feature'
  end

  it 'should split and trim labels' do
    result = @mapper.map(@story, 'AB')
    expect(result[:fields][:labels]).to eq ['a', 'b']
  end
end

describe JiraApi do
  it 'should post with correctly configured the url' do
    good_response = double(success?: true, body: '{"id": 1, "key": "TEST-1", "self":"http://localhost:8090/rest/api/2/issue/1"}')

    api = JiraApi.new
    api.configure!('http://server', 'user', 'pass', '2')

    expect(api).to receive(:post).with('http://server/rest/api/2/issue/', 'json', kind_of(Hash)).and_return good_response

    api.create_issue(double(to_json: 'json'))

  end

  it 'should raise error if the issue was not saved' do
    bad_response = double(success?: false, status: 401)
    issue = double(to_json: 'json')

    api = JiraApi.new
    api.configure!('http://server', 'user', 'pass', '2')

    expect(api).to receive(:post).and_return(bad_response)
    expect { api.create_issue(issue) }.to raise_error Exception
  end

end

describe Jira do

  before do
    @jira = Jira.new
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
        @raw_config = Hash[required.map {|v| [v, 'value']} ]
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

      handler = Jira.new(mapper, api)
      handler.configure! @config
      handler.handle @story do |status, response|
        expect(status).to be true
        expect(response).to include('TEST-1')
      end
    end

  end

end
