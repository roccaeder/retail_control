require "test_helper"

class StockMovementTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @product = create(:product, account: @account, stock: 20)
  end

  teardown { teardown_tenant }

  test "válido con atributos correctos" do
    movement = StockMovement.new(
      account:       @account,
      product:       @product,
      quantity:      5,
      movement_type: :sale
    )
    assert movement.valid?
  end

  test "inválido con quantity cero" do
    movement = StockMovement.new(account: @account, product: @product, quantity: 0, movement_type: :sale)
    assert_not movement.valid?
    assert movement.errors[:quantity].any?
  end

  test "inválido con quantity negativa" do
    movement = StockMovement.new(account: @account, product: @product, quantity: -3, movement_type: :purchase)
    assert_not movement.valid?
    assert movement.errors[:quantity].any?
  end

  test "enum movement_type incluye los 4 tipos" do
    assert_equal %w[sale purchase adjustment waste], StockMovement.movement_types.keys
  end

  test "origin polimórfico puede apuntar a una venta" do
    sale = create(:sale, account: @account)
    movement = StockMovement.create!(
      account:       @account,
      product:       @product,
      quantity:      1,
      movement_type: :sale,
      origin:        sale
    )
    assert_equal sale, movement.origin
  end

  test "aislamiento de tenant" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      other_product = create(:product, account: other_account)
      StockMovement.create!(account: other_account, product: other_product, quantity: 1, movement_type: :adjustment)
    end
    assert_equal 0, StockMovement.count
  end
end
