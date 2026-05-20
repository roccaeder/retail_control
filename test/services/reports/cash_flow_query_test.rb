require "test_helper"

class Reports::CashFlowQueryTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @customer = ActsAsTenant.with_tenant(@account) { create(:customer, account: @account) }
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  test "suma los ingresos del período" do
    sale = create(:sale, :pending, account: @account, customer: @customer, total: 100)
    Payment.create!(account: @account, sale: sale, amount: 60, payment_method: :cash, date: Date.current)
    result = call(from: Date.current, to: Date.current)
    assert_in_delta 60.0, result[:inflows], 0.01
  end

  test "suma los egresos del período" do
    Expense.create!(account: @account, category: "Alquiler", amount: 200, date: Date.current)
    result = call(from: Date.current, to: Date.current)
    assert_in_delta 200.0, result[:outflows], 0.01
  end

  test "calcula el neto correctamente" do
    sale = create(:sale, :pending, account: @account, customer: @customer, total: 100)
    Payment.create!(account: @account, sale: sale, amount: 80, payment_method: :cash, date: Date.current)
    Expense.create!(account: @account, category: "Servicios", amount: 30, date: Date.current)
    result = call(from: Date.current, to: Date.current)
    assert_in_delta 50.0, result[:net], 0.01
  end

  test "excluye registros fuera del período" do
    past = Date.current - 10
    sale = create(:sale, :pending, account: @account, customer: @customer, total: 100)
    Payment.create!(account: @account, sale: sale, amount: 100, payment_method: :cash, date: past)
    Expense.create!(account: @account, category: "X", amount: 50, date: past)
    result = call(from: Date.current, to: Date.current)
    assert_in_delta 0.0, result[:inflows], 0.01
    assert_in_delta 0.0, result[:outflows], 0.01
  end

  test "aislamiento de tenant: ignora pagos de otra cuenta" do
    other_account  = create(:account)
    other_customer = ActsAsTenant.with_tenant(other_account) { create(:customer, account: other_account) }
    ActsAsTenant.with_tenant(other_account) do
      sale = create(:sale, :pending, account: other_account, customer: other_customer, total: 500)
      Payment.create!(account: other_account, sale: sale, amount: 500, payment_method: :cash, date: Date.current)
    end
    result = call(from: Date.current, to: Date.current)
    assert_in_delta 0.0, result[:inflows], 0.01
  end

  private

  def call(from:, to:)
    Reports::CashFlowQuery.call(account: @account, from: from, to: to)
  end
end
