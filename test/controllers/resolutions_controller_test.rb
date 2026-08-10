require "test_helper"

class ResolutionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = create(:account)
    @user = create(:user, account: @account)
    @supplier = ActsAsTenant.with_tenant(@account) { create(:supplier, account: @account) }
    @supplier_import = ActsAsTenant.with_tenant(@account) { create(:supplier_import, account: @account, supplier: @supplier) }
    @product = ActsAsTenant.with_tenant(@account) { create(:product, account: @account, name: "Coca Cola 500ml") }
    sign_in @user
  end

  test "redirects to login when unauthenticated" do
    sign_out @user
    get supplier_import_resolutions_path(@supplier_import)
    assert_redirected_to new_user_session_path
  end

  test "supplier_import de otro tenant retorna 404" do
    other_account = create(:account)
    other_import = ActsAsTenant.with_tenant(other_account) do
      create(:supplier_import, account: other_account, supplier: create(:supplier, account: other_account))
    end

    get supplier_import_resolutions_path(other_import)
    assert_response :not_found
  end

  test "GET index solo muestra resolutions needs_review" do
    needs_review = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review, raw_name: "Necesita revisión")
    end
    ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :confirmed, product: @product, raw_name: "Ya confirmada")
    end

    get supplier_import_resolutions_path(@supplier_import)

    assert_response :success
    assert_match needs_review.raw_name, response.body
    assert_no_match(/Ya confirmada/, response.body)
  end

  test "PATCH update con product_id confirma la resolution" do
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review)
    end

    patch supplier_import_resolution_path(@supplier_import, resolution), params: { product_id: @product.id }

    assert_redirected_to supplier_import_resolutions_path(@supplier_import)
    assert ActsAsTenant.with_tenant(@account) { resolution.reload.confirmed? }
  end

  test "PATCH update con reject descarta la resolution" do
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review)
    end

    patch supplier_import_resolution_path(@supplier_import, resolution), params: { reject: true }

    assert_redirected_to supplier_import_resolutions_path(@supplier_import)
    assert ActsAsTenant.with_tenant(@account) { resolution.reload.rejected? }
  end

  test "PATCH update sin product_id ni reject redirige con alert" do
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review)
    end

    patch supplier_import_resolution_path(@supplier_import, resolution)

    assert_redirected_to supplier_import_resolutions_path(@supplier_import)
    assert flash[:alert].present?
    assert ActsAsTenant.with_tenant(@account) { resolution.reload.needs_review? }
  end

  test "POST create_product crea el producto y confirma la resolution" do
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review, raw_name: "Atun Lata 170g")
    end

    post create_product_supplier_import_resolution_path(@supplier_import, resolution),
      params: { product: { name: "Atún en Lata 170g", cost_price: 1.6, sale_price: 2.2, stock: 0 } }

    assert_redirected_to supplier_import_resolutions_path(@supplier_import)
    assert ActsAsTenant.with_tenant(@account) { Product.exists?(name: "Atún en Lata 170g") }
    assert ActsAsTenant.with_tenant(@account) { resolution.reload.confirmed? }
  end

  test "POST create_product sin nombre redirige con alert" do
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review)
    end

    post create_product_supplier_import_resolution_path(@supplier_import, resolution),
      params: { product: { name: "", cost_price: 1.6, sale_price: 2.2, stock: 0 } }

    assert_redirected_to supplier_import_resolutions_path(@supplier_import)
    assert flash[:alert].present?
    assert ActsAsTenant.with_tenant(@account) { resolution.reload.needs_review? }
  end

  test "resolution de otro supplier_import retorna 404" do
    other_import = ActsAsTenant.with_tenant(@account) { create(:supplier_import, account: @account, supplier: @supplier) }
    resolution = ActsAsTenant.with_tenant(@account) do
      create(:resolution, account: @account, supplier_import: other_import, status: :needs_review)
    end

    patch supplier_import_resolution_path(@supplier_import, resolution), params: { product_id: @product.id }

    assert_response :not_found
  end
end
