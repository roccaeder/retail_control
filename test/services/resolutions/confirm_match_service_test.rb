require "test_helper"

class Resolutions::ConfirmMatchServiceTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @user = create(:user, account: @account)
    @supplier = create(:supplier, account: @account)
    @supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    @product = create(:product, account: @account, name: "Coca Cola 500ml")
    @resolution = create(:resolution, account: @account, supplier_import: @supplier_import, status: :needs_review)
  end

  teardown { teardown_tenant }

  test "confirma la resolution con el producto elegido" do
    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user, product_id: @product.id)

    assert result.success
    assert @resolution.reload.confirmed?
    assert_equal @product, @resolution.product
    assert_equal @user, @resolution.reviewed_by
    assert_in_delta Time.current, @resolution.reviewed_at, 5.seconds
  end

  test "rechaza la resolution sin producto cuando reject es true" do
    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user, reject: true)

    assert result.success
    assert @resolution.reload.rejected?
    assert_nil @resolution.product
    assert_equal @user, @resolution.reviewed_by
  end

  test "falla con un mensaje claro si el product_id no existe" do
    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user, product_id: -1)

    assert_not result.success
    assert result.errors.present?
    assert @resolution.reload.needs_review?
  end

  test "falla si no se envía product_id ni reject" do
    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user)

    assert_not result.success
    assert @resolution.reload.needs_review?
  end

  test "acepta reject como string, como vendría de un form" do
    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user, reject: "true")

    assert result.success
    assert @resolution.reload.rejected?
  end

  test "falla con los errores del modelo si update! lanza RecordInvalid" do
    # No hay ninguna combinación alcanzable hoy que deje la resolution
    # inválida en este flujo — esto ejerce el rescue defensivo directamente.
    def @resolution.update!(*)
      errors.add(:base, "algo salió mal")
      raise ActiveRecord::RecordInvalid, self
    end

    result = Resolutions::ConfirmMatchService.call(resolution: @resolution, reviewed_by: @user, product_id: @product.id)

    assert_not result.success
    assert_equal [ "algo salió mal" ], result.errors
  end
end
