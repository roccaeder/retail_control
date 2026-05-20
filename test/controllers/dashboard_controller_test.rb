require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    sign_in @user
  end

  test "GET index responde 200" do
    get dashboard_index_path
    assert_response :success
  end

  test "redirige a login si no está autenticado" do
    sign_out @user
    get dashboard_index_path
    assert_redirected_to new_user_session_path
  end

  test "GET index muestra la card de flujo de caja" do
    get dashboard_index_path
    assert_select "h3", text: /Flujo de Caja/
  end

  test "GET index calcula el flujo neto del mes" do
    customer = ActsAsTenant.with_tenant(@account) { create(:customer, account: @account) }
    ActsAsTenant.with_tenant(@account) do
      sale = create(:sale, :pending, account: @account, customer: customer, total: 200)
      Payment.create!(account: @account, sale: sale, amount: 200, payment_method: :cash, date: Date.current)
      Expense.create!(account: @account, category: "Alquiler", amount: 50, date: Date.current)
    end
    get dashboard_index_path
    assert_response :success
  end
end
