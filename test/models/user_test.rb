require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    setup_tenant
  end

  teardown do
    teardown_tenant
  end

  test "válido con email, password y account" do
    user = User.new(
      email: "nuevo@example.com",
      password: "password123",
      password_confirmation: "password123",
      account: default_account
    )
    assert user.valid?
  end

  test "inválido sin account cuando no hay tenant activo" do
    # acts_as_tenant auto-asigna el tenant activo; lo limpiamos para testear la validación.
    ActsAsTenant.current_tenant = nil
    user = User.new(email: "x@x.com", password: "password123")
    assert_not user.valid?
    assert user.errors[:account].any?
  ensure
    setup_tenant
  end

  test "email debe ser único dentro del tenant" do
    user = User.new(
      email: users(:eder).email,
      password: "password123",
      account: default_account
    )
    assert_not user.valid?
  end

  test "pertenece al account correcto" do
    assert_equal default_account, users(:eder).account
  end
end
