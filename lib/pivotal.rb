# Pivotal handler
class Pivotal

  def supports(config)
    (config[:tracker] == nil && config[:project_id] != nil) || config[:tracker].downcase == 'pivotal'
  end

  def handle(yaml_story, config)

  end

end

#class BaseStory < ActiveResource::Base
#  cattr_accessor :config, :scheme
#
#  def self.configure(config)
#    self.config = config
#    self.scheme =  if !!self.config['ssl']
#                     self.ssl_options = {  :verify_mode => OpenSSL::SSL::VERIFY_PEER,
#                                           :ca_file => File.join(File.dirname(__FILE__), "cacert.pem") }
#                     "https"
#                   else
#                     "http"
#                   end
#  end
#
#end
#
#class Story < BaseStory
#
#  def self.configure(config)
#    super(config)
#
#    self.headers['X-TrackerToken'] = config.delete("token")
#    self.site = "#{scheme}://www.pivotaltracker.com/services/v3/projects/#{config['project_id']}"
#  end
#
#  def prepare
#    scrub_description
#    default_requested_by
#  end
#
#  protected
#
#  def scrub_description
#    if respond_to?(:description)
#      self.description = description.gsub('  ', '').gsub(" \n", "\n")
#    end
#    if respond_to?(:description) && description == ""
#      self.attributes["description"] = nil
#    end
#  end
#
#  def default_requested_by
#    if (!respond_to?(:requested_by) || requested_by == "") && config["requested_by"]
#      self.attributes["requested_by"] = config["requested_by"]
#    end
#  end
#
#end