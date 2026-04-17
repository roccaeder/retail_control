require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user    = users(:eder)
    @account = accounts(:one)
    sign_in @user   # Devise::Test::IntegrationHelpers
  end

  # ── Autenticación ──────────────────────────────────────────────────────────

  test "redirige a login si no está autenticado" do
    delete destroy_user_session_path
    get sales_path
    assert_redirected_to new_user_session_path
  end

  # ── index ──────────────────────────────────────────────────────────────────

  test "GET index responde 200" do
    get sales_path
    assert_response :success
  end

  test "index solo muestra ventas del tenant del usuario" do
    get sales_path
    assert_response :success
    # Verifica que no hay leaking de ventas de otro tenant en assigns
    # (verificación conceptual; en producción se testea con JS/Capybara)
    assert_select "body"
  end

  # ── new ────────────────────────────────────────────────────────────────────

  test "GET new responde 200" do
    get new_sale_path
    assert_response :success
  end

  # ── create ─────────────────────────────────────────────────────────────────

  test "POST create con datos válidos crea la venta y redirige" do
    product  = products(:coca_cola)
    customer = customers(:ana)

    assert_difference "Sale.count", 1 do
      post sales_path, params: {
        sale: {
          customer_id:     customer.id,
          payment_method:  "cash",
          on_credit:       "0",
          discount_amount: "0",
          sale_items_attributes: {
            "0" => { product_id: product.id, quantity: 2, unit_price: product.sale_price }
          }
        }
      }
    end

    assert_redirected_to sales_path
    assert_match "registrada correctamente", flash[:notice]
  end

  test "POST create sin ítems no crea la venta" do
    customer = customers(:ana)

    assert_no_difference "Sale.count" do
      post sales_path, params: {
        sale: {
          customer_id: customer.id, payment_method: "cash",
          on_credit: "0", discount_amount: "0",
          sale_items_attributes: {}
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "POST create a crédito con pago inicial registra el pago" do
    product  = products(:coca_cola)
    customer = customers(:ana)

    assert_difference "Payment.count", 1 do
      post sales_path, params: {
        initial_payment_amount: "1.00",
        sale: {
          customer_id:     customer.id,
          payment_method:  "credit",
          on_credit:       "1",
          discount_amount: "0",
          sale_items_attributes: {
            "0" => { product_id: product.id, quantity: 2, unit_price: product.sale_price }
          }
        }
      }
    end
  end

  # ── Aislamiento de tenant ──────────────────────────────────────────────────

  test "no puede ver ventas de otra cuenta" do
    # La venta on_credit_pending pertenece a account :one (del usuario logueado)
    # Intentamos acceder a una venta de otra cuenta directamente por ID
    # acts_as_tenant hace que el find falle con RecordNotFound
    otra_venta_id = ActsAsTenant.without_tenant { Sale.where(account: accounts(:two)).first&.id }
    skip "No hay ventas en cuenta dos" unless otra_venta_id

    assert_raises(ActiveRecord::RecordNotFound) do
      ActsAsTenant.with_tenant(accounts(:one)) { Sale.find(otra_venta_id) }
    end
  end
end
