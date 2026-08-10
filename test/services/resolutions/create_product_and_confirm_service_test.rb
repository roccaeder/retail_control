require "test_helper"

class Resolutions::CreateProductAndConfirmServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @user = create(:user, account: @account)
    @supplier = create(:supplier, account: @account)
    @supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    @resolution = create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review, raw_name: "Atun Lata 170g")
  end

  teardown { teardown_tenant }

  test "crea el producto y confirma la resolution contra él" do
    result = Resolutions::CreateProductAndConfirmService.call(
      resolution: @resolution,
      reviewed_by: @user,
      product_attributes: { name: "Atún en Lata 170g", cost_price: 1.6, sale_price: 2.2, stock: 0 }
    )

    assert result.success
    product = Product.find_by(name: "Atún en Lata 170g")
    assert product.present?
    assert_equal @account, product.account
    assert @resolution.reload.confirmed?
    assert_equal product, @resolution.product
    assert_equal @user, @resolution.reviewed_by
    assert_in_delta Time.current, @resolution.reviewed_at, 5.seconds
  end

  test "no crea el producto ni confirma si los datos son inválidos" do
    result = Resolutions::CreateProductAndConfirmService.call(
      resolution: @resolution,
      reviewed_by: @user,
      product_attributes: { name: "", cost_price: 1.6, sale_price: 2.2, stock: 0 }
    )

    assert_not result.success
    assert result.errors.present?
    assert_not Product.exists?(name: "")
    assert @resolution.reload.needs_review?
  end
end
