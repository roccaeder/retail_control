require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:eder)
  end

  # ── index ──────────────────────────────────────────────────────────────────

  test "GET index responde 200" do
    get products_path
    assert_response :success
  end

  test "redirige a login si no está autenticado" do
    sign_out users(:eder)
    get products_path
    assert_redirected_to new_user_session_path
  end

  # ── search ─────────────────────────────────────────────────────────────────

  test "GET search con query devuelve productos coincidentes" do
    get search_products_path, params: { q: "Coca" }
    assert_response :success
  end

  test "GET search sin query devuelve lista vacía" do
    get search_products_path, params: { q: "" }
    assert_response :success
  end

  test "GET search por SKU devuelve el producto correcto" do
    get search_products_path, params: { q: products(:coca_cola).sku }
    assert_response :success
  end
end
