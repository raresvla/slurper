require 'faraday'
require 'configliere'
require 'base64'
require 'json'
require 'jira/inflectors'

module Jira
  class Handler

    def initialize(jira_mapper = nil, jira_api = nil)
      @mapper = jira_mapper || StoryMapper.new
      @api = jira_api || ApiConsumer.new
    end

    def supports?(config)
      config.fetch('tracker', '').downcase == 'jira'
    end

    def configure!(config)
      settings = Configliere::Param.new

      settings.define :username, :required => true, :env_var => 'JIRA_USERNAME'
      settings.define :password, :required => true, :env_var => 'JIRA_PASSWORD'
      settings.define :url, :required => true
      settings.define :project, :required => true
      settings.define :mappings, :required => false

      settings.defaults api_version: 'latest', default_labels: '', mappings: {}

      settings.use(config)
      settings.resolve!

      @mapper.configure!(settings)
      @config = settings
    end

    def handle(yaml_story)
      @api.configure!(@config[:url], @config[:username], @config[:password], @config[:api_version])

      yaml_story['project'] = @config[:project]
      yaml_story['reporter'] = @config[:username]

      issue = @mapper.map(yaml_story)

      success, response_body = @api.create_issue(issue)
      response = JSON.parse response_body

      if success
        message = "Issue key = #{response['key']}, #{@config[:url]}/browse/#{response['key']}"
      else
        message = JSON.pretty_generate response
      end

      yield success, message
    end

  end

  class ApiConsumer

    def configure!(url, username, password, api_version = 'latest')
      @url = url
      @username = username
      @password = password
      @api_version = api_version
    end

    def create_issue(jira_story)
      response = post(url, jira_story.to_json, headers)
      return response.success?, response.body
    end

    protected

    def headers
      {'Content-Type' => 'application/json', 'Authorization' => auth_header}
    end

    def post(issues_url, json_data, headers)

      conn = Faraday.new do |faraday|
        faraday.headers = headers
        faraday.adapter  Faraday.default_adapter
      end

      conn.post do |req|
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

  class StoryMapper

    def initialize
      @map = default_mapping
    end

    def configure!(config)
      config[:mappings].each do |mapping|
        field, map = mapping
        @map[field] = map.to_hash
      end
    end

    def map(story)
      fields = story.to_hash.inject({}) do |hash, (key, value)|
        hash.merge!(do_map(key, value))
        hash
      end
      {:fields => fields}
    end

    private

    def default_mapping
      {
          :project => {
              :type => 'ProjectPicker'
          },
          :name => {
              :field_name => :summary,
              :type => 'TextField'
          },
          :description => {
              :type => 'FreeTextField'
          },
          :story_type => {
              :field_name => :issuetype,
              :type => 'SingleSelect'
          },
          :labels => {
              :type => 'Labels'
          },
          :reporter => {
              :type => 'SingleSelect'
          },
          :assignee => {
              :type => 'SingleSelect'
          }
      }
    end

    def do_map(key, value)
      map = @map[key.to_sym].tap do |m|
        raise "I don't know how to map '#{key}' to request. Please add it to your mappings config." if m.nil?
      end

      {map.fetch(:field_name, key).to_sym => Inflectors.factory(map.fetch(:type), value).value}
    end
  end
end
