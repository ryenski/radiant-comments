unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/boot"
end
require "#{RADIANT_ROOT}/test/test_helper"

class Test::Unit::TestCase
  test_helper :extension_fixtures, :extension_tags
  
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
end