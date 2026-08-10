require "test_helper"

class SupplierImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account  = create(:account)
    @user     = create(:user, account: @account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    sign_in @user
  end

  test "redirects to login when unauthenticated" do
    sign_out @user
    get supplier_imports_path
    assert_redirected_to new_user_session_path
  end

  test "supplier_import from another tenant returns 404" do
    other_account = create(:account)
    other_import = ActsAsTenant.with_tenant(other_account) do
      other_supplier = create(:supplier, account: other_account)
      import = create(:supplier_import, account: other_account, supplier: other_supplier)
      import
    end

    get supplier_import_path(other_import)
    assert_response :not_found
  end

  test "GET index renders successfully" do
    get supplier_imports_path
    assert_response :success
  end

  test "GET new renders form" do
    get new_supplier_import_path
    assert_response :success
    assert_select "form"
  end

  test "POST create adjunta el archivo, encola el job y redirige" do
    assert_enqueued_with(job: SupplierImportJob) do
      assert_difference -> { SupplierImport.count }, 1 do
        post supplier_imports_path, params: {
          supplier_import: {
            supplier_id: @supplier.id,
            file: fixture_file_upload("messy_supplier_products.csv", "text/csv")
          }
        }
      end
    end

    assert_redirected_to supplier_imports_path
    assert ActsAsTenant.with_tenant(@account) { SupplierImport.last.file.attached? }
  end

  test "POST create sin archivo re-renderiza el formulario" do
    assert_no_difference -> { SupplierImport.count } do
      post supplier_imports_path, params: { supplier_import: { supplier_id: @supplier.id } }
    end
    assert_response :unprocessable_entity
  end

  test "GET show renderiza el estado del import" do
    supplier_import = ActsAsTenant.with_tenant(@account) do
      import = create(:supplier_import, account: @account, supplier: @supplier)
      import
    end

    get supplier_import_path(supplier_import)
    assert_response :success
  end
end
