require "test_helper"

class SaleItemTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @customer = create(:customer, account: @account)
    @sale     = create(:sale, account: @account, customer: @customer)
    @product  = create(:product, account: @account)
    setup_tenant(@account)
  end

  teardown { teardown_tenant }

  # ── Asociaciones ──────────────────────────────────────────────────────────
  test "pertenece a una venta" do
    item = create(:sale_item, sale: @sale, product: @product, account: @account)
    assert_equal @sale, item.sale
  end

  test "pertenece a un producto" do
    item = create(:sale_item, sale: @sale, product: @product, account: @account)
    assert_equal @product, item.product
  end

  # ── Validaciones ──────────────────────────────────────────────────────────
  test "quantity debe ser entero mayor a 0" do
    item = build(:sale_item, sale: @sale, product: @product, account: @account, quantity: 0)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end

  test "unit_price no puede ser negativo" do
    item = build(:sale_item, sale: @sale, product: @product, account: @account, unit_price: -1)
    assert_not item.valid?
    assert item.errors[:unit_price].any?
  end

  # ── subtotal ──────────────────────────────────────────────────────────────
  test "subtotal = cantidad × precio − descuento" do
    item = build(:sale_item, sale: @sale, product: @product, account: @account,
                 quantity: 3, unit_price: 2.00, discount: 1.00)
    assert_equal 5.00, item.subtotal
  end

  test "factory genera sale_items válidos" do
    assert build(:sale_item, sale: @sale, product: @product, account: @account).valid?
  end
end
