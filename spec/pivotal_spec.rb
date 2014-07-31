require 'rubygems'
require 'slurper'
require 'pivotal'

describe Pivotal do

  before do
    @tracker = Pivotal.new
  end

  describe '#supports?' do
    it 'should support pivotal if project_id exists' do
      expect(@tracker.supports?({'project_id' => 12345})).to be true
    end

    it 'should support pivotal if specified' do
      expect(@tracker.supports?({'tracker' => 'pivotal'})).to be true
    end
  end

end
