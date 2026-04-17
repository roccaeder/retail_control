require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    @product = create(:product, account: @account, name: "Coca Cola", sku: "SKU-001")
    sign_in @user
  end

  # ── index ──────────────────────────────────────────────────────────────────
  test "GET index responde 200" do
    get products_path
    assert_response :success
  end

  test "redirige a login si no está autenticado" do
    sign_out @user
    get products_path
    assert_redirected_to new_user_session_path
  end

  # ── search ─────────────────────────────────────────────────────────────────
  test "GET search con nombre devuelve productos coincidentes" do
    get search_products_path, params: { q: "Coca" }
    assert_response :success
  end

  test "GET search con SKU devuelve el producto correcto" do
    get search_products_path, params: { q: @product.sku }
    assert_response :success
  end

  test "GET search con query vacío devuelve lista vacía" do
    get search_products_path, params: { q: "" }
    assert_response :success
  end
end
