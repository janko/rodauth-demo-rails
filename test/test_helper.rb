ENV['RAILS_ENV'] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

ActiveSupport::TestCase.fixtures :all
