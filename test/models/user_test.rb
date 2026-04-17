require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a un account" do
    user = create(:user, account: @account)
    assert_equal @account, user.account
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "válido con email, password y account" do
    assert build(:user, account: @account).valid?
  end

  test "inválido sin account cuando no hay tenant activo" do
    ActsAsTenant.current_tenant = nil
    user = build(:user, account: nil)
    assert_not user.valid?
    assert user.errors[:account].any?
  ensure
    setup_tenant(@account)
  end

  test "email debe ser único" do
    existing = create(:user, account: @account)
    duplicate = build(:user, email: existing.email, account: @account)
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?
  end

  test "pertenece al account correcto" do
    user = create(:user, account: @account)
    assert_equal @account, user.account
  end
end
