require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  test "válido con atributos mínimos" do
    supplier = Supplier.new(account: @account, name: "Distribuidora Norte")
    assert supplier.valid?
  end

  test "inválido sin nombre" do
    supplier = Supplier.new(account: @account, name: nil)
    assert_not supplier.valid?
    assert supplier.errors[:name].any?
  end

  test "pertenece a un account" do
    supplier = Supplier.create!(account: @account, name: "Proveedor X")
    assert_equal @account, supplier.account
  end

  test "aislamiento de tenant: no ve proveedores de otro account" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      Supplier.create!(account: other_account, name: "Proveedor Ajeno")
    end
    assert_equal 0, Supplier.count
  end
end
