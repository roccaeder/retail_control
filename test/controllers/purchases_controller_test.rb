require "test_helper"

class PurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    sign_in @user
  end

  # ── Security ──────────────────────────────────────────────────────────────
  test "redirects to login when unauthenticated" do
    sign_out @user
    get purchases_path
    assert_redirected_to new_user_session_path
  end

  test "purchase from another tenant returns 404" do
    other_account = create(:account)
    other_supplier = ActsAsTenant.with_tenant(other_account) { create(:supplier, account: other_account) }
    other_purchase = ActsAsTenant.with_tenant(other_account) { create(:purchase, account: other_account, supplier: other_supplier) }
    get purchase_path(other_purchase)
    assert_response :not_found
  end

  # ── GET index ─────────────────────────────────────────────────────────────
  test "GET index renders successfully" do
    get purchases_path
    assert_response :success
  end

  # ── GET new ───────────────────────────────────────────────────────────────
  test "GET new renders form" do
    get new_purchase_path
    assert_response :success
    assert_select "form"
  end

  # ── POST create ───────────────────────────────────────────────────────────
  test "POST create creates a draft purchase and redirects" do
    product = ActsAsTenant.with_tenant(@account) { create(:product, account: @account) }
    assert_difference -> { Purchase.count }, 1 do
      post purchases_path, params: {
        purchase: {
          supplier_id: @supplier.id,
          invoice_number: "FAC-001",
          purchase_items_attributes: {
            "0" => { product_id: product.id, quantity: 3, unit_cost: "5.00" }
          }
        }
      }
    end
    assert_redirected_to purchases_path
    assert Purchase.last.draft?
  end

  test "POST create with invalid params re-renders form" do
    post purchases_path, params: { purchase: { supplier_id: "" } }
    assert_response :unprocessable_entity
  end

  # ── PATCH receive ─────────────────────────────────────────────────────────
  test "PATCH receive transitions purchase to received" do
    product  = ActsAsTenant.with_tenant(@account) { create(:product, account: @account, stock: 10) }
    purchase = ActsAsTenant.with_tenant(@account) do
      p = create(:purchase, account: @account, supplier: @supplier)
      create(:purchase_item, purchase: p, product: product, account: @account, quantity: 5, unit_cost: 2.00)
      p
    end
    patch receive_purchase_path(purchase)
    assert_redirected_to purchases_path
    assert purchase.reload.received?
  end

  test "PATCH receive updates stock" do
    product  = ActsAsTenant.with_tenant(@account) { create(:product, account: @account, stock: 10) }
    purchase = ActsAsTenant.with_tenant(@account) do
      p = create(:purchase, account: @account, supplier: @supplier)
      create(:purchase_item, purchase: p, product: product, account: @account, quantity: 4, unit_cost: 1.50)
      p
    end
    patch receive_purchase_path(purchase)
    assert_equal 14, product.reload.stock
  end

  test "PATCH receive con servicio fallido redirige con alert" do
    product  = ActsAsTenant.with_tenant(@account) { create(:product, account: @account, stock: 10) }
    purchase = ActsAsTenant.with_tenant(@account) do
      p    = create(:purchase, account: @account, supplier: @supplier)
      item = create(:purchase_item, purchase: p, product: product, account: @account, quantity: 1, unit_cost: 2.00)
      item.update_column(:quantity, 0)
      p
    end
    patch receive_purchase_path(purchase)
    assert_redirected_to purchases_path
    assert flash[:alert].present?
  end
end
