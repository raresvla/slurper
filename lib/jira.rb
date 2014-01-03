require 'faraday'
require 'configliere'
require 'base64'

# Jira handler
class Jira

  def initialize(jira_mapper = nil, jira_api = nil)
    @mapper = jira_mapper || JiraStoryMapper.new
    @api = jira_api || JiraApi.new
  end

  def supports?(config)
    config.fetch(:tracker, '').downcase == 'jira'
  end

  def configure!(config)
    settings = Configliere::Param.new

    settings.define :username, :required => true, :env_var => 'JIRA_USERNAME'
    settings.define :password, :required => true, :env_var => 'JIRA_PASSWORD'
    settings.define :url, :required => true
    settings.define :project, :required => true

    settings.defaults api_version: 'latest', default_labels: ''

    settings.use(config)
    settings.resolve!

    @config = settings
  end

  def handle(yaml_story)
    @api.configure!(@config[:url], @config[:username], @config[:password], @config[:api_version])

    issue = @mapper.map(yaml_story, @config[:project])

    @api.create_issue(issue)
  end

end

class JiraApi

  def configure!(url, username, password, api_version = 'latest')
    @url = url
    @username = username
    @password = password
    @api_version = api_version
  end

  def create_issue(jira_story)
    response = post(url, jira_story.to_json, headers)

    if not response.success? then
      raise Exception.new "#{response.status} #{response.body}"
    end
  end

  protected

  def headers
    return {'Content-Type' => 'application/json', 'Authorization' => auth_header}
  end

  def post(issues_url, json_data, headers)

    conn = Faraday.new do |faraday|
      faraday.headers = headers
      faraday.adapter  Faraday.default_adapter
    end

    return conn.post do |req|
      req.url issues_url
      req.body = json_data
    end

  end

  def url
    "#{@url}/rest/api/#{@api_version}/issue/"
  end

  def auth_header
    login = Base64.encode64 @username + ':' + @password
    "Basic #{login}"
  end

end

class JiraStoryMapper

  def map(story, project)
    hash = {}
    hash[:project] = {:key => project}
    hash[:summary] = story.name
    hash[:description] = story.description
    hash[:issuetype] = {:name => story.story_type}

    if story.labels then
      hash[:labels] = story.labels.map {|label| label.gsub(' ', '_')}
    end

    return { :fields => hash }
  end
end