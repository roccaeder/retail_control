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
end
