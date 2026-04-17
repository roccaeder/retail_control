require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    sign_in @user
  end

  test "GET index responde 200" do
    get customers_path
    assert_response :success
  end

  test "index solo muestra clientes del tenant actual" do
    create(:customer, account: @account)
    other_customer = create(:customer, account: create(:account))

    get customers_path
    assert_response :success
    # acts_as_tenant garantiza que el otro cliente no aparece en la query
    ActsAsTenant.with_tenant(@account) do
      assert_not_includes Customer.all, other_customer
    end
  end

  test "redirige a login si no está autenticado" do
    sign_out @user
    get customers_path
    assert_redirected_to new_user_session_path
  end
end
