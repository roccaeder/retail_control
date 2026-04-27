require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    sign_in @user
  end

  # ── Security ──────────────────────────────────────────────────────────────
  describe "security" do
    test "redirects to login when unauthenticated" do
      sign_out @user
      get sales_path
      assert_redirected_to new_user_session_path
    end

    test "returns 404 for sales from other tenants" do
      other_account = create(:account)
      other_sale    = ActsAsTenant.with_tenant(other_account) { create(:sale) }

      get sale_path(other_sale)
      assert_response :not_found
    end
  end

  # ── GET index ─────────────────────────────────────────────────────────────
  describe "GET #index" do
    test "shows empty state when no sales exist" do
      get sales_path
      assert_response :success
      assert_select "p", text: "No hay ventas registradas"
    end

    test "lists sales with customer names" do
      customer = create(:customer, account: @account)
      ActsAsTenant.with_tenant(@account) do
        create(:sale, customer: customer)
        create(:sale, customer: customer)
      end

      get sales_path
      assert_response :success
      assert_select "[data-test='customer-name']", minimum: 2
    end
  end

  # ── GET new ───────────────────────────────────────────────────────────────
  describe "GET #new" do
    test "renders the new sale form" do
      get new_sale_path
      assert_response :success
    end
  end

  # ── GET show ──────────────────────────────────────────────────────────────
  describe "GET #show" do
    setup do
      @customer = create(:customer, account: @account)
      @sale     = ActsAsTenant.with_tenant(@account) { create(:sale, customer: @customer) }
    end

    test "renders the sale detail page" do
      get sale_path(@sale)
      assert_response :success
    end

    test "shows associated payments" do
      ActsAsTenant.with_tenant(@account) do
        create(:payment, sale: @sale, amount: 5.0)
      end
      get sale_path(@sale)
      assert_response :success
    end
  end

  # ── POST create ───────────────────────────────────────────────────────────
  describe "POST #create" do
    setup do
      @customer = create(:customer, account: @account)
      @product1 = create(:product, account: @account, sale_price: 1.68)
      @product2 = create(:product, account: @account, sale_price: 2.68)
    end

    def sale_params(overrides = {})
      {
        sale: {
          customer_id:    @customer.id,
          payment_method: "cash",
          on_credit:      "0",
          discount_amount: "0",
          amount_received: "0",
          sale_items_attributes: {
            "0" => { product_id: @product1.id, quantity: 2, unit_price: @product1.sale_price },
            "1" => { product_id: @product2.id, quantity: 1, unit_price: @product2.sale_price }
          }
        }.merge(overrides)
      }
    end

    test "creates sale with items and redirects" do
      assert_difference -> { Sale.count } => 1, -> { SaleItem.count } => 2 do
        post sales_path, params: sale_params
      end

      assert_redirected_to sales_path
      assert_match /registrada correctamente/, flash[:notice]
    end

    test "should decrease stock of products when sale is created" do
      assert_difference -> { @product1.reload.stock } => -2, -> { @product2.reload.stock } => -1 do
        post sales_path, params: sale_params
      end

      assert_redirected_to sales_path # o el path que uses tras guardar
    end

    test "returns 422 when no items are submitted" do
      params = sale_params
      params[:sale][:sale_items_attributes] = {}

      assert_no_difference "Sale.count" do
        post sales_path, params: params
      end
      assert_response :unprocessable_entity
    end

    test "assigns Consumidor Final when no customer is selected" do
      params = sale_params
      params[:sale].delete(:customer_id)

      assert_difference "Sale.count", 1 do
        post sales_path, params: params
      end

      assert_equal "Consumidor Final", Sale.last.customer.name
    end

    test "calculates total as subtotal minus discount" do
      post sales_path, params: sale_params(discount_amount: "1.00")

      expected_total = (@product1.sale_price * 2 + @product2.sale_price) - 1.0
      assert_in_delta expected_total, Sale.last.total, 0.001
    end

    test "registers a payment for the full total on a cash sale" do
      assert_difference "Payment.count", 1 do
        post sales_path, params: sale_params
      end

      expected_total = @product1.sale_price * 2 + @product2.sale_price
      assert_in_delta expected_total, Payment.last.amount, 0.001
    end

    test "sale is marked as paid after a full cash payment" do
      post sales_path, params: sale_params
      assert_predicate Sale.last, :paid?
    end

    test "returns 422 and rolls back when payment registration fails" do
      full_discount = (@product1.sale_price * 2 + @product2.sale_price).to_s

      assert_no_difference -> { Sale.count } do
        post sales_path, params: sale_params(discount_amount: full_discount)
      end
      assert_response :unprocessable_entity
    end

    test "sets sale_date as a datetime on creation" do
      freeze_time do
        post sales_path, params: sale_params
        assert_equal Time.current, Sale.last.sale_date
      end
    end

    # ── Crédito ─────────────────────────────────────────────────────────────
    test "creates credit sale and registers payment for amount_received only" do
      assert_difference -> { Sale.count } => 1, -> { Payment.count } => 1 do
        post sales_path, params: sale_params(on_credit: "1", amount_received: "2.00")
      end

      assert_redirected_to sales_path
      assert_in_delta 2.0, Payment.last.amount, 0.001
    end

    test "credit sale is marked as partial after partial initial payment" do
      post sales_path, params: sale_params(on_credit: "1", amount_received: "2.00")
      assert_predicate Sale.last, :partial?
    end

    test "returns 422 for credit sale without a customer" do
      params = sale_params(on_credit: "1", amount_received: "5.00")
      params[:sale].delete(:customer_id)

      assert_no_difference "Sale.count" do
        post sales_path, params: params
      end
      assert_response :unprocessable_entity
    end

    test "returns 422 for credit sale with amount_received of zero" do
      assert_no_difference "Sale.count" do
        post sales_path, params: sale_params(on_credit: "1", amount_received: "0")
      end
      assert_response :unprocessable_entity
    end

    test "returns 422 for credit sale with negative amount_received" do
      assert_no_difference "Sale.count" do
        post sales_path, params: sale_params(on_credit: "1", amount_received: "-5")
      end
      assert_response :unprocessable_entity
    end
  end
end
