require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user    = create(:user, account: @account)
    sign_in @user
  end

  # ── Security ──────────────────────────────────────────────────────────────
  test "redirects to login when unauthenticated" do
    sign_out @user
    get expenses_path
    assert_redirected_to new_user_session_path
  end

  # ── GET index ─────────────────────────────────────────────────────────────
  test "GET index renders successfully" do
    get expenses_path
    assert_response :success
  end

  test "GET index muestra el flujo de caja del mes" do
    get expenses_path
    assert_select "table", count: 0
  end

  test "GET index lista los gastos del tenant" do
    ActsAsTenant.with_tenant(@account) do
      Expense.create!(account: @account, category: "Alquiler", amount: 300, date: Date.current)
    end
    get expenses_path
    assert_response :success
    assert_select "table"
  end

  # ── GET new ───────────────────────────────────────────────────────────────
  test "GET new renders form" do
    get new_expense_path
    assert_response :success
    assert_select "form"
  end

  # ── POST create ───────────────────────────────────────────────────────────
  test "POST create registra el gasto y redirige" do
    assert_difference -> { Expense.count }, 1 do
      post expenses_path, params: {
        expense: {
          category:    "Alquiler",
          amount:      500.00,
          date:        Date.current.to_s,
          description: "Pago mensual"
        }
      }
    end
    assert_redirected_to expenses_path
  end

  test "POST create asigna el tenant al gasto" do
    post expenses_path, params: {
      expense: { category: "Servicios básicos", amount: 80, date: Date.current.to_s }
    }
    assert_equal @account, Expense.last.account
  end

  test "POST create con datos inválidos re-renderiza el formulario" do
    post expenses_path, params: { expense: { category: "", amount: 0, date: "" } }
    assert_response :unprocessable_entity
  end

  test "POST create con amount negativo falla" do
    post expenses_path, params: {
      expense: { category: "Alquiler", amount: -10, date: Date.current.to_s }
    }
    assert_response :unprocessable_entity
  end

  # ── DELETE destroy ────────────────────────────────────────────────────────
  test "DELETE destroy elimina el gasto" do
    expense = ActsAsTenant.with_tenant(@account) do
      Expense.create!(account: @account, category: "Transporte", amount: 20, date: Date.current)
    end
    assert_difference -> { Expense.count }, -1 do
      delete expense_path(expense)
    end
    assert_redirected_to expenses_path
  end

  test "DELETE destroy de otro tenant retorna 404" do
    other_account = create(:account)
    other_expense = ActsAsTenant.with_tenant(other_account) do
      Expense.create!(account: other_account, category: "X", amount: 10, date: Date.current)
    end
    delete expense_path(other_expense)
    assert_response :not_found
  end
end
