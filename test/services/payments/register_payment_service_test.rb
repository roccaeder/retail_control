require "test_helper"

class Payments::RegisterPaymentServiceTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    @sale     = create(:sale, :pending, account: @account, customer: @customer, total: 4.50)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Pago completo ──────────────────────────────────────────────────────────
  test "pago completo marca la venta como paid" do
    result = call(amount: @sale.total)
    assert result.success
    assert @sale.reload.paid?
  end

  test "pago completo deja balance_due en 0" do
    call(amount: @sale.total)
    assert_equal 0.0, @sale.reload.balance_due.to_f
  end

  # ── Pago parcial ───────────────────────────────────────────────────────────
  test "pago parcial marca la venta como partial" do
    result = call(amount: 2.00)
    assert result.success
    assert @sale.reload.partial?
  end

  test "pago parcial reduce balance_due correctamente" do
    call(amount: 2.00)
    assert_in_delta 2.50, @sale.reload.balance_due, 0.01
  end

  # ── Deuda del cliente ──────────────────────────────────────────────────────
  test "pago completo reduce la deuda del cliente a 0" do
    @customer.update!(current_debt: @sale.total)
    call(amount: @sale.total)
    assert_equal 0.0, @customer.reload.current_debt.to_f
  end

  test "pago parcial actualiza la deuda al saldo pendiente real" do
    call(amount: 2.00)
    expected = @customer.sales.where(status: [ :pending, :partial ]).sum { |s| s.balance_due }
    assert_in_delta expected, @customer.reload.current_debt, 0.01
  end

  # ── Validaciones ───────────────────────────────────────────────────────────
  test "monto 0 retorna fallo sin crear pago" do
    assert_no_difference "Payment.count" do
      result = call(amount: 0)
      assert_not result.success
      assert result.errors.any?
    end
  end

  test "payment_method nil retorna fallo" do
    result = call(amount: 2.00, payment_method: nil)
    assert_not result.success
  end

  # ── Múltiples pagos acumulativos ───────────────────────────────────────────
  test "varios pagos parciales saldan la venta al llegar al total" do
    sale = create(:sale, :partial, account: @account, customer: @customer, total: 10.00)
    create(:payment, sale: sale, account: @account, amount: 4.00)

    call(sale: sale, amount: 3.00)
    call(sale: sale, amount: 3.00)

    assert sale.reload.paid?
    assert_equal 0.0, sale.balance_due.to_f
  end

  # ── WebMock: sin llamadas HTTP externas ───────────────────────────────────
  test "el service no hace llamadas HTTP externas" do
    # WebMock lanzará error si hubiera algún request no stubbeado
    assert_nothing_raised { call(amount: @sale.total) }
  end

  private

  def call(sale: @sale, amount:, payment_method: :cash, date: Date.today)
    Payments::RegisterPaymentService.call(
      sale: sale, amount: amount, payment_method: payment_method, date: date
    )
  end
end
