# SimpleCov debe cargarse ANTES que Rails para instrumentar todo el código.
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

  # Umbral actual. Subir gradualmente al agregar más tests.
  # Meta: 80% líneas / 70% ramas.
  minimum_coverage line: 75, branch: 60
end

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
