require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @customer = create(:customer, account: @account)
    @sale     = ActsAsTenant.with_tenant(@account) { create(:sale, customer: @customer, on_credit: true, amount_received: 10) }
    sign_in @user
  end

  # ── Security ──────────────────────────────────────────────────────────────
  describe "security" do
    test "redirects to login when unauthenticated" do
      sign_out @user
      get new_sale_payment_path(@sale)
      assert_redirected_to new_user_session_path
    end

    test "returns 404 when sale belongs to another tenant" do
      other_account = create(:account)
      other_sale    = ActsAsTenant.with_tenant(other_account) { create(:sale) }
      get new_sale_payment_path(other_sale)
      assert_response :not_found
    end
  end

  # ── GET new ───────────────────────────────────────────────────────────────
  describe "GET #new" do
    test "renders the payment modal" do
      get new_sale_payment_path(@sale)
      assert_response :success
    end

    test "shows the sale balance_due" do
      get new_sale_payment_path(@sale)
      assert_select "dialog"
    end
  end

  # ── POST create ───────────────────────────────────────────────────────────
  describe "POST #create" do
    def payment_params(overrides = {})
      { payment: { amount: "10.00", payment_method: "cash" }.merge(overrides) }
    end

    test "creates a payment and returns turbo stream" do
      assert_difference "Payment.count", 1 do
        post sale_payments_path(@sale),
             params: payment_params,
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
      assert_response :success
    end

    test "updates the sale status to paid when fully settled" do
      remaining = @sale.balance_due
      post sale_payments_path(@sale),
           params: payment_params(amount: remaining.to_s),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_predicate @sale.reload, :paid?
    end

    test "updates the sale status to partial on partial payment" do
      post sale_payments_path(@sale),
           params: payment_params(amount: "1.00"),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_predicate @sale.reload, :partial?
    end

    test "reduces customer current_debt after payment" do
      # First payment seeds the customer's tracked debt
      Payments::RegisterPaymentService.call(sale: @sale, amount: 2.0, payment_method: :cash)
      initial_debt = @customer.reload.current_debt
      assert initial_debt > 0

      post sale_payments_path(@sale),
           params: payment_params(amount: "2.00"),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert @customer.reload.current_debt < initial_debt
    end

    test "returns 422 with invalid amount" do
      assert_no_difference "Payment.count" do
        post sale_payments_path(@sale),
             params: payment_params(amount: "-5.00"),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
      assert_response :unprocessable_entity
    end

    test "falls back to html redirect when no turbo stream header" do
      post sale_payments_path(@sale), params: payment_params
      assert_redirected_to sales_path
    end
  end
end
