require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    setup_tenant
  end

  teardown do
    teardown_tenant
  end

  test "válido con datos correctos" do
    customer = Customer.new(name: "Test Cliente", debt_limit: 500, current_debt: 0, account: default_account)
    assert customer.valid?
  end

  test "inválido sin nombre" do
    customer = Customer.new(debt_limit: 500, current_debt: 0, account: default_account)
    assert_not customer.valid?
    assert customer.errors[:name].any?
  end

  test "within_debt_limit? es true cuando deuda <= límite" do
    customer = customers(:ana)
    customer.current_debt = customer.debt_limit
    assert customer.within_debt_limit?
  end

  test "within_debt_limit? es false cuando deuda > límite" do
    customer = customers(:ana)
    customer.current_debt = customer.debt_limit + 1
    assert_not customer.within_debt_limit?
  end

  test "solo devuelve clientes del tenant actual" do
    ids_del_tenant = Customer.all.map(&:account_id).uniq
    assert_equal [ default_account.id ], ids_del_tenant
  end

  test "no ve clientes de otras cuentas" do
    assert_not_includes Customer.all, customers(:rosa)
  end
end
