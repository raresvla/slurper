require 'rubygems'
require 'slurper'
require 'pivotal'

describe Pivotal do

  before do
    @tracker = Pivotal.new
  end

  describe "#supports?" do
    it "should support pivotal if project_id exists" do
      @tracker.supports?({:project_id => 12345}).should == true
    end

    it "should support pivotal if specified" do
      @tracker.supports?({:tracker => 'pivotal'}).should == true
    end
  end

end

#describe Story do
#
#  before do
#    fixture = File.join(File.dirname(__FILE__), "fixtures", "slurper_config_pivotal.yml")
#    Story.configure(YAML.load_file fixture)
#  end
#
#  context "#prepare" do
#
#    it "uses http by default" do
#      Story.scheme.should == "http"
#      Story.config['ssl'].should be_nil
#    end
#
#    it "uses https if set in the config" do
#      Story.configure({"ssl" => true})
#
#      Story.config['ssl'].should be_true
#      Story.scheme.should == "https"
#      Story.ssl_options[:verify_mode].should == 1
#
#      # Not sure what this next line is testing
#      File.open(File.expand_path('lib/cacert.pem')).readlines.find_all{ |l| l.starts_with?("Equifax") }.count.should == 4
#    end
#
#    it "sets the api token from config" do
#      Story.headers.should == {"X-TrackerToken"=>"123abc123abc123abc123abc"}
#    end
#  end
#
#
#
#
#
#end
