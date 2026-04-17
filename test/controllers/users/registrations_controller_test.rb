require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # ── GET new ────────────────────────────────────────────────────────────────

  test "GET new muestra el formulario de registro" do
    get new_user_registration_path
    assert_response :success
  end

  # ── POST create — éxito ────────────────────────────────────────────────────

  test "POST create con datos válidos crea account y user" do
    assert_difference [ "Account.count", "User.count" ], 1 do
      post user_registration_path, params: {
        account: { name: "Nueva Tienda", subdomain: "nueva-tienda" },
        user:    { email: "nuevo@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
  end

  test "POST create exitoso redirige al root" do
    post user_registration_path, params: {
      account: { name: "Tienda XYZ", subdomain: "tienda-xyz" },
      user:    { email: "xyz@example.com", password: "password123", password_confirmation: "password123" }
    }
    assert_redirected_to root_path
  end

  test "POST create exitoso deja al usuario logueado" do
    post user_registration_path, params: {
      account: { name: "Tienda ABC", subdomain: "tienda-abc" },
      user:    { email: "abc@example.com", password: "password123", password_confirmation: "password123" }
    }
    follow_redirect!
    assert_response :success
  end

  # ── POST create — account inválida ─────────────────────────────────────────

  test "POST create con subdomain inválido no crea nada" do
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "X", subdomain: "Subdomain Inválido!" },
        user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create con subdomain duplicado no crea nada" do
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "X", subdomain: accounts(:one).subdomain },
        user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create con account inválida muestra el error en flash" do
    post user_registration_path, params: {
      account: { name: "", subdomain: "" },
      user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
    }
    assert_response :unprocessable_entity
    assert flash[:alert].present?
  end

  # ── POST create — user inválido ────────────────────────────────────────────

  test "POST create con password no coincidente no crea nada" do
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "Tienda OK", subdomain: "tienda-ok" },
        user:    { email: "ok@example.com", password: "password123", password_confirmation: "otra" }
      }
    end
  end

  test "POST create con email ya registrado en otra cuenta no duplica el user" do
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        account: { name: "Tienda Nueva", subdomain: "tienda-nueva" },
        user:    { email: users(:eder).email, password: "password123", password_confirmation: "password123" }
      }
    end
  end
end
