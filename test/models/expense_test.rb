require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  test "válido con atributos mínimos" do
    expense = Expense.new(account: @account, category: "Alquiler", amount: 100, date: Date.current)
    assert expense.valid?
  end

  test "inválido sin categoría" do
    expense = Expense.new(account: @account, category: nil, amount: 100, date: Date.current)
    assert_not expense.valid?
    assert expense.errors[:category].any?
  end

  test "inválido sin fecha" do
    expense = Expense.new(account: @account, category: "Alquiler", amount: 100, date: nil)
    assert_not expense.valid?
    assert expense.errors[:date].any?
  end

  test "amount debe ser mayor a 0" do
    expense = Expense.new(account: @account, category: "Alquiler", amount: 0, date: Date.current)
    assert_not expense.valid?
    assert expense.errors[:amount].any?
  end

  test "aislamiento de tenant" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      Expense.create!(account: other_account, category: "X", amount: 10, date: Date.current)
    end
    assert_equal 0, Expense.count
  end
end
