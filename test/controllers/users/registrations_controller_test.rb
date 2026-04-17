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

  test "usuario queda logueado tras el registro" do
    post user_registration_path, params: {
      account: { name: "Tienda ABC", subdomain: "tienda-abc" },
      user:    { email: "abc@example.com", password: "password123", password_confirmation: "password123" }
    }
    follow_redirect!
    assert_response :success
  end

  # ── POST create — account inválida ─────────────────────────────────────────
  test "subdomain inválido no crea nada" do
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "X", subdomain: "Subdomain Inválido!" },
        user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "subdomain duplicado no crea nada" do
    existing = create(:account)
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "X", subdomain: existing.subdomain },
        user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "account inválida muestra error en flash" do
    post user_registration_path, params: {
      account: { name: "", subdomain: "" },
      user:    { email: "x@example.com", password: "password123", password_confirmation: "password123" }
    }
    assert_response :unprocessable_entity
    assert flash[:alert].present?
  end

  # ── POST create — user inválido ────────────────────────────────────────────
  test "password no coincidente no crea nada" do
    assert_no_difference [ "Account.count", "User.count" ] do
      post user_registration_path, params: {
        account: { name: "Tienda OK", subdomain: "tienda-ok" },
        user:    { email: "ok@example.com", password: "password123", password_confirmation: "otra" }
      }
    end
  end

  test "email ya registrado no crea un segundo user" do
    existing_user = create(:user)
    assert_no_difference "User.count" do
      post user_registration_path, params: {
        account: { name: "Tienda Nueva", subdomain: "tienda-nueva" },
        user:    { email: existing_user.email, password: "password123", password_confirmation: "password123" }
      }
    end
  end
end
