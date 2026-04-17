require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a un account" do
    customer = create(:customer, account: @account)
    assert_equal @account, customer.account
  end

  test "tiene ventas" do
    assert_respond_to Customer.new, :sales
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "inválido sin nombre" do
    customer = build(:customer, name: nil, account: @account)
    assert_not customer.valid?
    assert customer.errors[:name].any?
  end

  test "debt_limit no puede ser negativo" do
    customer = build(:customer, debt_limit: -1, account: @account)
    assert_not customer.valid?
    assert customer.errors[:debt_limit].any?
  end

  test "current_debt no puede ser negativo" do
    customer = build(:customer, current_debt: -1, account: @account)
    assert_not customer.valid?
    assert customer.errors[:current_debt].any?
  end

  # ── within_debt_limit? ────────────────────────────────────────────────────
  test "within_debt_limit? es true cuando deuda <= límite" do
    assert build(:customer, debt_limit: 500, current_debt: 500).within_debt_limit?
  end

  test "within_debt_limit? es false cuando deuda > límite" do
    assert_not build(:customer, debt_limit: 500, current_debt: 501).within_debt_limit?
  end

  # ── Aislamiento de tenant ─────────────────────────────────────────────────
  test "solo devuelve clientes del tenant actual" do
    create(:customer, account: @account)
    other_account  = create(:account)
    other_customer = ActsAsTenant.with_tenant(other_account) { create(:customer, account: other_account) }

    assert_not_includes Customer.all, other_customer
  end
end
