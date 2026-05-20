require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    sign_in @user
  end

  # ── Security ──────────────────────────────────────────────────────────────
  test "redirects to login when unauthenticated" do
    sign_out @user
    get suppliers_path
    assert_redirected_to new_user_session_path
  end

  # ── GET index ─────────────────────────────────────────────────────────────
  test "GET index renders successfully" do
    get suppliers_path
    assert_response :success
    assert_select "table"
  end

  # ── GET show ──────────────────────────────────────────────────────────────
  test "GET show renders supplier details" do
    get supplier_path(@supplier)
    assert_response :success
  end

  # ── GET new ───────────────────────────────────────────────────────────────
  test "GET new renders form" do
    get new_supplier_path
    assert_response :success
    assert_select "form"
  end

  # ── POST create ───────────────────────────────────────────────────────────
  test "POST create creates supplier and redirects" do
    assert_difference -> { Supplier.count }, 1 do
      post suppliers_path, params: { supplier: { name: "Distribuidora Central", phone: "555-1234" } }
    end
    assert_redirected_to suppliers_path
  end

  test "POST create with invalid params re-renders form" do
    post suppliers_path, params: { supplier: { name: "" } }
    assert_response :unprocessable_entity
  end

  # ── GET edit ──────────────────────────────────────────────────────────────
  test "GET edit renders form with supplier data" do
    get edit_supplier_path(@supplier)
    assert_response :success
    assert_select "form"
  end

  # ── PATCH update ──────────────────────────────────────────────────────────
  test "PATCH update changes supplier name" do
    patch supplier_path(@supplier), params: { supplier: { name: "Nuevo Nombre" } }
    assert_redirected_to suppliers_path
    assert_equal "Nuevo Nombre", @supplier.reload.name
  end

  test "PATCH update with invalid params re-renders edit" do
    patch supplier_path(@supplier), params: { supplier: { name: "" } }
    assert_response :unprocessable_entity
  end

  # ── DELETE destroy ────────────────────────────────────────────────────────
  test "DELETE destroy removes supplier" do
    assert_difference -> { Supplier.count }, -1 do
      delete supplier_path(@supplier)
    end
    assert_redirected_to suppliers_path
  end

  test "DELETE destroy with associated purchases shows alert" do
    product  = ActsAsTenant.with_tenant(@account) { create(:product, account: @account) }
    purchase = ActsAsTenant.with_tenant(@account) { create(:purchase, account: @account, supplier: @supplier) }
    ActsAsTenant.with_tenant(@account) do
      create(:purchase_item, purchase: purchase, product: product, account: @account)
    end
    delete supplier_path(@supplier)
    assert_redirected_to suppliers_path
    assert_equal @supplier, Supplier.find_by(id: @supplier.id)
  end

  # ── Tenant isolation ──────────────────────────────────────────────────────
  test "supplier from another tenant returns 404 on edit" do
    other_account  = create(:account)
    other_supplier = ActsAsTenant.with_tenant(other_account) { create(:supplier, account: other_account) }
    get edit_supplier_path(other_supplier)
    assert_response :not_found
  end
end
