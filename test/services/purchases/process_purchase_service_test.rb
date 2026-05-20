require "test_helper"

class Purchases::ProcessPurchaseServiceTest < ActiveSupport::TestCase
  setup do
    @account  = create(:account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    setup_tenant(@account)
    @product  = create(:product, account: @account, stock: 10, cost_price: 1.00)
    @purchase = create(:purchase, account: @account, supplier: @supplier)
    @item     = create(:purchase_item, purchase: @purchase, product: @product,
                       account: @account, quantity: 5, unit_cost: 3.00)
  end

  teardown { teardown_tenant }

  # ── Estado draft: sin efecto en stock ─────────────────────────────────────
  test "una compra en borrador no modifica el stock" do
    assert_equal 10, @product.reload.stock
  end

  # ── Recepción exitosa ──────────────────────────────────────────────────────
  test "receive cambia status a received" do
    call
    assert @purchase.reload.received?
  end

  test "receive incrementa el stock del producto" do
    call
    assert_equal 15, @product.reload.stock
  end

  test "receive actualiza el cost_price del producto" do
    call
    assert_in_delta 3.00, @product.reload.cost_price, 0.001
  end

  test "receive calcula el total de la compra" do
    call
    assert_in_delta 15.00, @purchase.reload.total, 0.01
  end

  test "receive establece received_date con la fecha actual" do
    call
    assert_equal Date.current, @purchase.reload.received_date
  end

  test "receive crea un stock_movement con origin=purchase" do
    assert_difference -> { StockMovement.count }, 1 do
      call
    end
    movement = StockMovement.last
    assert_equal @purchase, movement.origin
    assert movement.purchase?
    assert_equal 5, movement.quantity
  end

  test "retorna success=true con la compra" do
    result = call
    assert result.success
    assert_instance_of Purchase, result.purchase
    assert_empty result.errors
  end

  # ── Fallo interno del servicio ────────────────────────────────────────────
  # quantity: 0 bypasses PurchaseItem validation but StockMovement rejects it,
  # so RegisterMovementService returns success: false → covers the unless branch.
  test "retorna failure si RegisterMovementService falla" do
    @item.update_column(:quantity, 0)
    result = call
    assert_not result.success
    assert_nil result.purchase
    assert result.errors.any?
  end

  test "no modifica el stock si el servicio de movimiento falla" do
    @item.update_column(:quantity, 0)
    call
    assert_equal 10, @product.reload.stock
  end

  test "mantiene status draft si el servicio falla" do
    @item.update_column(:quantity, 0)
    call
    assert @purchase.reload.draft?
  end

  # ── Dos items ──────────────────────────────────────────────────────────────
  test "calcula total correctamente con múltiples items" do
    product2 = create(:product, account: @account, stock: 20)
    create(:purchase_item, purchase: @purchase, product: product2, account: @account, quantity: 2, unit_cost: 10.00)
    call
    assert_in_delta 35.00, @purchase.reload.total, 0.01
  end

  private

  def call
    Purchases::ProcessPurchaseService.call(purchase: @purchase)
  end
end
