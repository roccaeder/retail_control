require "test_helper"

class SaleTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a un customer" do
    sale = create(:sale, account: @account, customer: @customer)
    assert_equal @customer, sale.customer
  end

  test "pertenece a un account" do
    sale = create(:sale, account: @account, customer: @customer)
    assert_equal @account, sale.account
  end

  test "tiene sale_items" do
    assert_respond_to Sale.new, :sale_items
  end

  test "tiene payments" do
    assert_respond_to Sale.new, :payments
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "total no puede ser negativo" do
    sale = build(:sale, account: @account, customer: @customer, total: -1)
    assert_not sale.valid?
    assert sale.errors[:total].any?
  end

  # ── Enums ─────────────────────────────────────────────────────────────────
  test "status paid tiene valor 0"    do assert_equal 0, Sale.statuses[:paid]    end
  test "status pending tiene valor 1" do assert_equal 1, Sale.statuses[:pending] end
  test "status partial tiene valor 2" do assert_equal 2, Sale.statuses[:partial] end

  # ── balance_due ────────────────────────────────────────────────────────────
  test "balance_due es 0 para venta totalmente pagada" do
    sale = create(:sale, account: @account, customer: @customer, total: 10.00)
    create(:payment, sale: sale, account: @account, amount: 10.00)
    assert_equal 0.0, sale.balance_due.to_f
  end

  test "balance_due es el total cuando no hay pagos" do
    sale = create(:sale, :pending, account: @account, customer: @customer, total: 4.50)
    assert_equal 4.50, sale.balance_due.to_f
  end

  test "balance_due descuenta pagos parciales" do
    sale = create(:sale, :partial, account: @account, customer: @customer, total: 10.00)
    create(:payment, sale: sale, account: @account, amount: 4.00)
    assert_in_delta 6.00, sale.balance_due, 0.01
  end

  # ── auto_set_status ────────────────────────────────────────────────────────
  test "venta al contado se auto-marca como paid" do
    sale = build(:sale, account: @account, customer: @customer, on_credit: false, payment_method: :cash)
    sale.valid?
    assert sale.paid?
  end

  test "venta a crédito se auto-marca como pending" do
    sale = build(:sale, account: @account, customer: @customer, on_credit: true, payment_method: :credit)
    sale.valid?
    assert sale.pending?
  end

  # ── Aislamiento de tenant ─────────────────────────────────────────────────
  test "Sale.all no incluye ventas de otro tenant" do
    create(:sale, account: @account, customer: @customer)
    other_account  = create(:account)
    other_customer = create(:customer, account: other_account)
    other_sale     = ActsAsTenant.with_tenant(other_account) do
      create(:sale, account: other_account, customer: other_customer)
    end

    assert_not_includes Sale.all, other_sale
  end
end
