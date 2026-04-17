ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    fixtures :all

    def with_tenant(account, &block)
      ActsAsTenant.with_tenant(account, &block)
    end

    def default_account
      accounts(:one)
    end

    def other_account
      accounts(:two)
    end

    def setup_tenant(account = default_account)
      ActsAsTenant.current_tenant = account
    end

    def teardown_tenant
      ActsAsTenant.current_tenant = nil
    end
  end
end

# Devise helpers para integration tests (ActionDispatch::IntegrationTest)
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
