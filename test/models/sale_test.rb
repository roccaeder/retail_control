require "test_helper"

class SaleTest < ActiveSupport::TestCase
  setup do
    setup_tenant
  end

  teardown do
    teardown_tenant
  end

  # ── Enums ──────────────────────────────────────────────────────────────────

  test "status paid tiene valor 0" do
    assert_equal 0, Sale.statuses[:paid]
  end

  test "status pending tiene valor 1" do
    assert_equal 1, Sale.statuses[:pending]
  end

  test "status partial tiene valor 2" do
    assert_equal 2, Sale.statuses[:partial]
  end

  # ── balance_due ────────────────────────────────────────────────────────────

  test "balance_due es 0 para venta pagada" do
    sale = sales(:paid_cash)
    assert_equal 0.0, sale.balance_due.to_f
  end

  test "balance_due es igual al total para venta pendiente sin pagos" do
    sale = sales(:on_credit_pending)
    assert_equal sale.total.to_f, sale.balance_due.to_f
  end

  test "balance_due descuenta pagos parciales" do
    sale = sales(:on_credit_partial)
    pago = payments(:partial_payment).amount.to_f
    assert_in_delta sale.total - pago, sale.balance_due, 0.01
  end

  # ── Generación de código ───────────────────────────────────────────────────

  test "code único dentro del tenant" do
    codes = Sale.pluck(:code).compact
    assert_equal codes.uniq, codes
  end

  # ── Aislamiento de tenant ──────────────────────────────────────────────────

  test "Sale.all no incluye ventas de otro tenant" do
    all_account_ids = Sale.all.map(&:account_id).uniq
    assert_equal [default_account.id], all_account_ids
  end

  # ── auto_set_status ────────────────────────────────────────────────────────

  test "sale al contado se crea como paid" do
    sale = Sale.new(
      customer: customers(:ana), payment_method: :cash,
      on_credit: false, subtotal: 5, total: 5, account: default_account
    )
    sale.valid?
    assert sale.paid?
  end

  test "sale a crédito se crea como pending" do
    sale = Sale.new(
      customer: customers(:ana), payment_method: :credit,
      on_credit: true, subtotal: 5, total: 5, account: default_account
    )
    sale.valid?
    assert sale.pending?
  end
end
