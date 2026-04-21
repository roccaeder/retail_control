require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    sign_in @user
  end

  describe "security" do
    test "should redirect to login when unauthenticated" do
      sign_out @user
      get sales_path
      assert_redirected_to new_user_session_path
    end

    test "should not access or leak sales from other tenants" do
      other_account = create(:account)
      other_sale    = ActsAsTenant.with_tenant(other_account) { create(:sale) }

      get sale_path(other_sale)
      assert_no_match "/sales/#{other_sale.id}", response.body
      assert_response :not_found
    end
  end

  describe "GET #index when empty" do
    test "shows empty state message" do
      get sales_path
      assert_response :success
      assert_select "p", text: "No hay ventas registradas"
    end
  end

  describe "GET actions" do
    setup do
      @customer = create(:customer, account: @account)
      @sale     = ActsAsTenant.with_tenant(@account) { create(:sale, customer: @customer) }
    end

    test "should render index and new" do
      [sales_path, new_sale_path].each do |path|
        get path
        assert_response :success
      end
    end

    test "index should list sales with customer names" do
      ActsAsTenant.with_tenant(@account) { create(:sale, customer: @customer) }
      get sales_path(@sale)
      assert_select "[data-test='customer-name']", text: @customer.name
      assert_select "table tbody tr", count: 2
    end
  end

  # --- Contexto: Creación de Ventas (POST) ---
  describe "POST #create" do
    setup do
      @customer = create(:customer, account: @account)
      @product1  = create(:product, account: @account, sale_price: 1.68)
      @product2 = create(:product, account: @account, sale_price: 2.68)
    end

    def sale_params(overrides = {})
      {
        sale: {
          customer_id: @customer.id,
          payment_method: "cash",
          on_credit: "0",
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

    test "returns 422 when items are missing" do
      invalid_params = sale_params
      invalid_params[:sale][:sale_items_attributes] = {}

      assert_no_difference "Sale.count" do
        post sales_path, params: invalid_params
      end
      assert_response :unprocessable_entity
    end

    test "registers a payment when creating a credit sale with initial amount" do
      params = sale_params(payment_method: "credit", on_credit: "1")
      params[:initial_payment_amount] = "1.00"

      assert_difference "Payment.count", 1 do
        post sales_path, params: params
      end
    end
  end
end
