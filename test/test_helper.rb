ENV['RAILS_ENV'] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class SystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test
end
