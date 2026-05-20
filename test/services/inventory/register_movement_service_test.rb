require "test_helper"

class Inventory::RegisterMovementServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @product = create(:product, account: @account, stock: 10)
  end

  teardown { teardown_tenant }

  # ── Entradas (purchase / adjustment) ──────────────────────────────────────
  test "purchase incrementa el stock del producto" do
    call(quantity: 5, movement_type: :purchase)
    assert_equal 15, @product.reload.stock
  end

  test "adjustment incrementa el stock del producto" do
    call(quantity: 3, movement_type: :adjustment)
    assert_equal 13, @product.reload.stock
  end

  test "compra exitosa crea un stock_movement" do
    assert_difference -> { StockMovement.count }, 1 do
      call(quantity: 5, movement_type: :purchase)
    end
  end

  test "compra exitosa retorna success=true y el movement" do
    result = call(quantity: 5, movement_type: :purchase)
    assert result.success
    assert_instance_of StockMovement, result.movement
    assert_empty result.errors
  end

  # ── Salidas (sale / waste) ─────────────────────────────────────────────────
  test "sale decrementa el stock del producto" do
    call(quantity: 4, movement_type: :sale)
    assert_equal 6, @product.reload.stock
  end

  test "waste decrementa el stock del producto" do
    call(quantity: 2, movement_type: :waste)
    assert_equal 8, @product.reload.stock
  end

  # ── Stock insuficiente ─────────────────────────────────────────────────────
  test "sale con stock insuficiente retorna failure" do
    result = call(quantity: 20, movement_type: :sale)
    assert_not result.success
    assert_nil result.movement
    assert result.errors.any?
  end

  test "sale con stock insuficiente no cambia el stock" do
    call(quantity: 20, movement_type: :sale)
    assert_equal 10, @product.reload.stock
  end

  test "sale con stock insuficiente no crea stock_movement" do
    assert_no_difference -> { StockMovement.count } do
      call(quantity: 20, movement_type: :sale)
    end
  end

  # ── Origin polimórfico ─────────────────────────────────────────────────────
  test "guarda el origin cuando se pasa" do
    sale = create(:sale, account: @account)
    result = call(quantity: 1, movement_type: :sale, origin: sale)
    assert_equal sale, result.movement.origin
  end

  private

  def call(quantity:, movement_type:, origin: nil, description: nil)
    Inventory::RegisterMovementService.call(
      product:       @product,
      quantity:      quantity,
      movement_type: movement_type,
      origin:        origin,
      description:   description
    )
  end
end
