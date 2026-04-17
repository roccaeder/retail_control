require "test_helper"

class Payments::RegisterPaymentServiceTest < ActiveSupport::TestCase
  setup do
    setup_tenant
    @sale    = sales(:on_credit_pending)   # total: 4.50, sin pagos
    @customer = customers(:luis)
  end

  teardown do
    teardown_tenant
  end

  # ── Pago completo ──────────────────────────────────────────────────────────

  test "pago completo pone la venta en estado paid" do
    result = Payments::RegisterPaymentService.call(
      sale: @sale, amount: @sale.total, payment_method: :cash, date: Date.today
    )

    assert result.success
    assert @sale.reload.paid?
  end

  test "pago completo deja balance_due en 0" do
    Payments::RegisterPaymentService.call(
      sale: @sale, amount: @sale.total, payment_method: :cash, date: Date.today
    )

    assert_equal 0.0, @sale.reload.balance_due.to_f
  end

  # ── Pago parcial ───────────────────────────────────────────────────────────

  test "pago parcial pone la venta en estado partial" do
    result = Payments::RegisterPaymentService.call(
      sale: @sale, amount: 2.00, payment_method: :cash, date: Date.today
    )

    assert result.success
    assert @sale.reload.partial?
  end

  test "pago parcial reduce balance_due correctamente" do
    Payments::RegisterPaymentService.call(
      sale: @sale, amount: 2.00, payment_method: :cash, date: Date.today
    )

    assert_in_delta 2.50, @sale.reload.balance_due, 0.01
  end

  # ── Deuda del cliente ──────────────────────────────────────────────────────

  test "pago completo elimina la deuda del cliente" do
    deuda_previa = @customer.current_debt.to_f

    Payments::RegisterPaymentService.call(
      sale: @sale, amount: @sale.total, payment_method: :cash, date: Date.today
    )

    assert @customer.reload.current_debt < deuda_previa || @customer.reload.current_debt == 0
  end

  test "pago parcial actualiza la deuda del cliente al saldo pendiente" do
    Payments::RegisterPaymentService.call(
      sale: @sale, amount: 2.00, payment_method: :cash, date: Date.today
    )

    expected_debt = @customer.sales.where(status: [ :pending, :partial ]).sum { |s| s.balance_due }
    assert_in_delta expected_debt, @customer.reload.current_debt, 0.01
  end

  # ── Validaciones ───────────────────────────────────────────────────────────

  test "retorna fallo si el monto es 0" do
    result = Payments::RegisterPaymentService.call(
      sale: @sale, amount: 0, payment_method: :cash, date: Date.today
    )

    assert_not result.success
    assert result.errors.any?
  end

  test "retorna fallo sin payment_method" do
    result = Payments::RegisterPaymentService.call(
      sale: @sale, amount: 2.0, payment_method: nil, date: Date.today
    )

    assert_not result.success
  end

  # ── Múltiples pagos acumulativos ───────────────────────────────────────────

  test "múltiples pagos parciales acumulan hasta saldar la venta" do
    sale = sales(:on_credit_partial)   # total: 10.00, tiene 1 pago de 4.00

    Payments::RegisterPaymentService.call(
      sale: sale, amount: 3.00, payment_method: :cash, date: Date.today
    )
    Payments::RegisterPaymentService.call(
      sale: sale, amount: 3.00, payment_method: :cash, date: Date.today
    )

    assert sale.reload.paid?, "Se esperaba estado :paid después de pagar el total"
    assert_equal 0.0, sale.balance_due.to_f
  end
end
