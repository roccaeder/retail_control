require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    setup_tenant
  end

  teardown do
    teardown_tenant
  end

  test "válido con datos correctos" do
    payment = Payment.new(
      sale:           sales(:on_credit_pending),
      amount:         2.00,
      payment_method: :cash,
      date:           Date.today,
      account:        default_account
    )
    assert payment.valid?
  end

  test "inválido con monto cero" do
    payment = Payment.new(
      sale: sales(:on_credit_pending), amount: 0,
      payment_method: :cash, date: Date.today, account: default_account
    )
    assert_not payment.valid?
    assert payment.errors[:amount].any?
  end

  test "inválido con monto negativo" do
    payment = Payment.new(
      sale: sales(:on_credit_pending), amount: -5,
      payment_method: :cash, date: Date.today, account: default_account
    )
    assert_not payment.valid?
  end

  test "inválido sin fecha" do
    payment = Payment.new(
      sale: sales(:on_credit_pending), amount: 2,
      payment_method: :cash, date: nil, account: default_account
    )
    assert_not payment.valid?
    assert payment.errors[:date].any?
  end

  test "pertenece al tenant correcto" do
    assert_equal default_account, payments(:full_payment).account
  end
end
