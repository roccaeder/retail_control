require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a un account" do
    product = create(:product, account: @account)
    assert_equal @account, product.account
  end

  test "tiene sale_items" do
    assert_respond_to Product.new, :sale_items
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "inválido sin nombre" do
    assert_not build(:product, name: nil, account: @account).valid?
  end

  test "sale_price no puede ser negativo" do
    product = build(:product, sale_price: -1, account: @account)
    assert_not product.valid?
    assert product.errors[:sale_price].any?
  end

  test "cost_price no puede ser negativo" do
    product = build(:product, cost_price: -1, account: @account)
    assert_not product.valid?
    assert product.errors[:cost_price].any?
  end

  test "stock no puede ser negativo" do
    product = build(:product, stock: -1, account: @account)
    assert_not product.valid?
    assert product.errors[:stock].any?
  end

  # ── Unicidad de SKU por tenant ─────────────────────────────────────────────
  test "SKU duplicado en la misma cuenta es inválido" do
    create(:product, account: @account, sku: "SKU-DUP")
    assert_not build(:product, account: @account, sku: "SKU-DUP").valid?
  end

  test "el mismo SKU en otra cuenta es válido" do
    create(:product, account: @account, sku: "SKU-DUP")
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      assert build(:product, account: other_account, sku: "SKU-DUP").valid?
    end
  end

  # ── Aislamiento de tenant ─────────────────────────────────────────────────
  test "no devuelve productos de otro tenant" do
    create(:product, account: @account)
    other_account = create(:account)
    other_product = ActsAsTenant.with_tenant(other_account) { create(:product, account: other_account) }

    assert_not_includes Product.all, other_product
  end
end
