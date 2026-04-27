require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @customer = create(:customer, account: @account, name: "Juan Pérez", phone: "912345678")
    sign_in @user
  end

  # ── Security ───────────────────────────────────────────────────────────────
  describe "security" do
    test "redirects to login when unauthenticated" do
      sign_out @user
      get customers_path
      assert_redirected_to new_user_session_path
    end

    test "returns 404 for a customer from another tenant" do
      other_account   = create(:account)
      other_customer  = ActsAsTenant.with_tenant(other_account) { create(:customer) }

      get customer_path(other_customer)
      assert_response :not_found
    end
  end

  # ── GET index ──────────────────────────────────────────────────────────────
  describe "GET #index" do
    test "responds 200" do
      get customers_path
      assert_response :success
    end

    test "lists customers of the current account only" do
      other_account = create(:account)
      ActsAsTenant.with_tenant(other_account) { create(:customer, name: "Otro") }

      get customers_path
      assert_select "td", text: /Juan Pérez/
      assert_select "td", text: /Otro/, count: 0
    end
  end

  # ── GET show ───────────────────────────────────────────────────────────────
  describe "GET #show" do
    test "renders the customer detail page" do
      get customer_path(@customer)
      assert_response :success
    end

    test "displays the customer name" do
      get customer_path(@customer)
      assert_select "h1", text: /Juan Pérez/
    end

    test "shows associated sales" do
      ActsAsTenant.with_tenant(@account) do
        create(:sale, customer: @customer)
      end
      get customer_path(@customer)
      assert_response :success
    end
  end

  # ── GET new ────────────────────────────────────────────────────────────────
  describe "GET #new" do
    test "renders the new customer form" do
      get new_customer_path
      assert_response :success
    end
  end

  # ── POST create ────────────────────────────────────────────────────────────
  describe "POST #create" do
    def valid_params(overrides = {})
      { customer: { name: "María López", phone: "987654321", debt_limit: "500.00" }.merge(overrides) }
    end

    test "creates a customer and redirects to index" do
      assert_difference "Customer.count", 1 do
        post customers_path, params: valid_params
      end
      assert_redirected_to customers_path
      assert_match /creado correctamente/, flash[:notice]
    end

    test "assigns the customer to the current account" do
      post customers_path, params: valid_params
      assert_equal @account, Customer.last.account
    end

    test "returns 422 when name is blank" do
      assert_no_difference "Customer.count" do
        post customers_path, params: valid_params(name: "")
      end
      assert_response :unprocessable_entity
    end

    test "returns 422 when debt_limit is negative" do
      assert_no_difference "Customer.count" do
        post customers_path, params: valid_params(debt_limit: "-100")
      end
      assert_response :unprocessable_entity
    end

    test "creates a customer without phone" do
      assert_difference "Customer.count", 1 do
        post customers_path, params: valid_params(phone: "")
      end
      assert_redirected_to customers_path
    end
  end

  # ── Consumidor Final (cliente genérico) ────────────────────────────────────
  describe "generic customer protection" do
    setup do
      @generic = create(:customer, account: @account, name: "Consumidor Final", debt_limit: 0, current_debt: 0)
    end

    test "cannot edit Consumidor Final" do
      get edit_customer_path(@generic)
      assert_redirected_to customers_path
      assert_match /no puede modificarse/, flash[:alert]
    end

    test "cannot update Consumidor Final" do
      patch customer_path(@generic), params: { customer: { name: "Otro" } }
      assert_redirected_to customers_path
      assert_match /no puede modificarse/, flash[:alert]
      assert_equal "Consumidor Final", @generic.reload.name
    end

    test "cannot destroy Consumidor Final" do
      assert_no_difference "Customer.count" do
        delete customer_path(@generic)
      end
      assert_redirected_to customers_path
      assert_match /no puede modificarse/, flash[:alert]
    end
  end

  # ── GET edit ───────────────────────────────────────────────────────────────
  describe "GET #edit" do
    test "renders the edit form" do
      get edit_customer_path(@customer)
      assert_response :success
    end
  end

  # ── PATCH update ───────────────────────────────────────────────────────────
  describe "PATCH #update" do
    test "updates the customer and redirects to index" do
      patch customer_path(@customer), params: { customer: { name: "Juan García" } }
      assert_redirected_to customers_path
      assert_match /actualizado correctamente/, flash[:notice]
      assert_equal "Juan García", @customer.reload.name
    end

    test "returns 422 when name is blank" do
      patch customer_path(@customer), params: { customer: { name: "" } }
      assert_response :unprocessable_entity
      assert_equal "Juan Pérez", @customer.reload.name
    end

    test "returns 422 when debt_limit is negative" do
      patch customer_path(@customer), params: { customer: { debt_limit: "-50" } }
      assert_response :unprocessable_entity
    end
  end

  # ── DELETE destroy ─────────────────────────────────────────────────────────
  describe "DELETE #destroy" do
    test "deletes the customer and redirects to index" do
      assert_difference "Customer.count", -1 do
        delete customer_path(@customer)
      end
      assert_redirected_to customers_path
      assert_match /eliminado correctamente/, flash[:notice]
    end

    test "does not delete a customer that has associated sales" do
      ActsAsTenant.with_tenant(@account) do
        create(:sale, customer: @customer)
      end

      assert_no_difference "Customer.count" do
        delete customer_path(@customer)
      end
      assert_redirected_to customers_path
      assert flash[:alert].present?
    end
  end
end
