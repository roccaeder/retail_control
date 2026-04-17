require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    @sale     = create(:sale, :pending, account: @account, customer: @customer)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a una venta" do
    payment = create(:payment, sale: @sale, account: @account)
    assert_equal @sale, payment.sale
  end

  test "pertenece a un account" do
    payment = create(:payment, sale: @sale, account: @account)
    assert_equal @account, payment.account
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "amount debe ser mayor a 0" do
    assert_not build(:payment, sale: @sale, account: @account, amount: 0).valid?
  end

  test "amount negativo es inválido" do
    assert_not build(:payment, sale: @sale, account: @account, amount: -1).valid?
  end

  test "date no puede ser nil" do
    payment = build(:payment, sale: @sale, account: @account, date: nil)
    assert_not payment.valid?
    assert payment.errors[:date].any?
  end

  test "válido con datos completos" do
    assert build(:payment, sale: @sale, account: @account).valid?
  end
end
