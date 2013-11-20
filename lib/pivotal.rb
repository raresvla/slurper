# Pivotal handler
class Pivotal

  def initialize(pivotal_api = nil)
    @api = pivotal_api || PivotalApi.new
  end

  def supports?(config)
    (config[:tracker] == nil && config[:project_id] != nil) || config[:tracker].downcase == 'pivotal'
  end

  def configure!(config)
    settings = Configliere::Param.new

    settings.define :project_id, :required => true
    settings.define :token, :required => true, :env_var => 'PIVOTAL_TOKEN'

    settings.use(config)
    settings.resolve!

    @config = settings
  end

  def handle(yaml_story)
    @api.configure!(@config.project_id, @config.token)
    @api.create_story(yaml_story)
  end

end

class PivotalApi

  def configure!(project, token)
    @token = token
    @project = project
  end

  def create_story(yaml_story)
    story = {
        story_type: yaml_story.story_type,
        name: yaml_story.name,
        description: yaml_story.description,
        labels: yaml_story.labels.map { |label| {:name => label} },
        #requested_by_id: yaml_story.requested_by
    }

    response = post(url('stories'), story.to_json, headers)

    if not response.success? then
      raise Exception.new "#{response.status} #{response.body}"
    end
  end

  protected

  def headers
    return {'Content-Type' => 'application/json', 'X-TrackerToken' => @token}
  end

  def post(issues_url, json_data, headers)
    conn = Faraday.new(ssl={:verify => false}) do |faraday|
      faraday.headers = headers
      faraday.adapter Faraday.default_adapter
    end

    return conn.post do |req|
      req.url issues_url
      req.body = json_data
    end

  end

  def url(resource)
    "https://www.pivotaltracker.com/services/v5/projects/#{@project}/#{resource}"
  end
end