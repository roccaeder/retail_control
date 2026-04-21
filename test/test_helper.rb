require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/vendor/"
  add_group "Models",      "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services",    "app/services"
  minimum_coverage line: 75, branch: 60
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/spec"

require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

require "shoulda/matchers"
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

module ActiveSupport
  class TestCase
    extend Minitest::Spec::DSL

    include FactoryBot::Syntax::Methods

    def setup_tenant(account)
      ActsAsTenant.current_tenant = account
    end

    def teardown_tenant
      ActsAsTenant.current_tenant = nil
    end

    def assert_matcher(matcher, subject)
      assert matcher.matches?(subject), matcher.failure_message
    end

    def refute_matcher(matcher, subject)
      assert_not matcher.matches?(subject), matcher.failure_message_when_negated
    end
  end
end

# Devise helpers para ActionDispatch::IntegrationTest
class ActionDispatch::IntegrationTest
  extend Minitest::Spec::DSL

  include FactoryBot::Syntax::Methods
  include Devise::Test::IntegrationHelpers
end
