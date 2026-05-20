require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  test "válido con atributos mínimos" do
    purchase = Purchase.new(account: @account, supplier: @supplier)
    assert purchase.valid?
  end

  test "inválido sin proveedor" do
    purchase = Purchase.new(account: @account, supplier: nil)
    assert_not purchase.valid?
    assert purchase.errors[:supplier].any?
  end

  test "enum status tiene draft, received, cancelled" do
    assert_equal %w[draft received cancelled], Purchase.statuses.keys
  end

  test "estado inicial es draft" do
    purchase = create(:purchase, account: @account, supplier: @supplier)
    assert purchase.draft?
  end

  test "aislamiento de tenant" do
    other_account = create(:account)
    other_supplier = ActsAsTenant.with_tenant(other_account) { create(:supplier, account: other_account) }
    ActsAsTenant.with_tenant(other_account) do
      Purchase.create!(account: other_account, supplier: other_supplier)
    end
    assert_equal 0, Purchase.count
  end
end
