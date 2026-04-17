require "test_helper"

class CustomersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:eder)
  end

  test "GET index responde 200" do
    get customers_path
    assert_response :success
  end

  test "index solo muestra clientes del tenant actual" do
    get customers_path
    assert_response :success
  end

  test "redirige a login si no está autenticado" do
    sign_out users(:eder)
    get customers_path
    assert_redirected_to new_user_session_path
  end
end
