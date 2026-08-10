require "test_helper"

class SupplierImportTest < ActiveSupport::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @supplier = create(:supplier, account: @account)
  end

  teardown { teardown_tenant }

  test "válido con atributos mínimos y archivo adjunto" do
    supplier_import = build(:supplier_import, account: @account, supplier: @supplier)
    assert supplier_import.valid?
  end

  test "inválido sin archivo" do
    supplier_import = SupplierImport.new(account: @account, supplier: @supplier)
    assert_not supplier_import.valid?
    assert supplier_import.errors[:file].any?
  end

  test "inválido sin supplier" do
    supplier_import = build(:supplier_import, account: @account, supplier: nil)
    assert_not supplier_import.valid?
  end

  test "status por defecto es pending" do
    supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    assert supplier_import.pending?
  end

  test "enum status incluye los 4 estados" do
    assert_equal %w[pending processing completed failed], SupplierImport.statuses.keys
  end

  test "borrar un supplier_import borra sus resolutions" do
    supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    create(:resolution, account: @account, supplier_import: supplier_import)

    assert_difference -> { Resolution.count }, -1 do
      supplier_import.destroy
    end
  end

  test "aislamiento de tenant: no ve imports de otro account" do
    other_account = create(:account)
    ActsAsTenant.with_tenant(other_account) do
      other_supplier = create(:supplier, account: other_account)
      create(:supplier_import, account: other_account, supplier: other_supplier)
    end
    assert_equal 0, SupplierImport.count
  end
end
