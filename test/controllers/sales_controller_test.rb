require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @customer = create(:customer, account: @account)
    @product  = create(:product, account: @account, stock: 20, sale_price: 1.68)
    sign_in @user
  end

  # ── Autenticación ──────────────────────────────────────────────────────────
  test "redirige a login si no está autenticado" do
    sign_out @user
    get sales_path
    assert_redirected_to new_user_session_path
  end

  # ── index ──────────────────────────────────────────────────────────────────
  test "GET index responde 200" do
    get sales_path
    assert_response :success
  end

  test "index no expone ventas de otro tenant" do
    other_account  = create(:account)
    other_customer = create(:customer, account: other_account)
    other_sale     = ActsAsTenant.with_tenant(other_account) do
      create(:sale, account: other_account, customer: other_customer)
    end

    get sales_path
    ActsAsTenant.with_tenant(@account) do
      assert_not_includes Sale.all, other_sale
    end
  end

  # ── new ────────────────────────────────────────────────────────────────────
  test "GET new responde 200" do
    get new_sale_path
    assert_response :success
  end

  # ── show ───────────────────────────────────────────────────────────────────
  test "GET show responde 200" do
    sale = ActsAsTenant.with_tenant(@account) { create(:sale, account: @account, customer: @customer) }
    get sale_path(sale)
    assert_response :success
  end

  test "venta de otro tenant no es visible en el tenant actual" do
    other_account  = create(:account)
    other_customer = create(:customer, account: other_account)
    other_sale     = ActsAsTenant.with_tenant(other_account) do
      create(:sale, account: other_account, customer: other_customer)
    end

    ActsAsTenant.with_tenant(@account) do
      assert_raises(ActiveRecord::RecordNotFound) { Sale.find(other_sale.id) }
    end
  end

  # ── create ─────────────────────────────────────────────────────────────────
  test "POST create con datos válidos crea la venta y redirige" do
    assert_difference "Sale.count", 1 do
      post sales_path, params: {
        sale: {
          customer_id:     @customer.id,
          payment_method:  "cash",
          on_credit:       "0",
          discount_amount: "0",
          sale_items_attributes: {
            "0" => { product_id: @product.id, quantity: 2, unit_price: @product.sale_price }
          }
        }
      }
    end
    assert_redirected_to sales_path
    assert_match "registrada correctamente", flash[:notice]
  end

  test "POST create sin ítems devuelve 422" do
    assert_no_difference "Sale.count" do
      post sales_path, params: {
        sale: {
          customer_id: @customer.id, payment_method: "cash",
          on_credit: "0", discount_amount: "0",
          sale_items_attributes: {}
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create a crédito con pago inicial registra el pago" do
    assert_difference "Payment.count", 1 do
      post sales_path, params: {
        initial_payment_amount: "1.00",
        sale: {
          customer_id:     @customer.id,
          payment_method:  "credit",
          on_credit:       "1",
          discount_amount: "0",
          sale_items_attributes: {
            "0" => { product_id: @product.id, quantity: 2, unit_price: @product.sale_price }
          }
        }
      }
    end
  end
end
