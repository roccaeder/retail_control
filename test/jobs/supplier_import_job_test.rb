require "test_helper"

class SupplierImportJobTest < ActiveJob::TestCase
  setup do
    @account = create(:account)
    setup_tenant(@account)
    @supplier = create(:supplier, account: @account)
    create(:product, account: @account, name: "Coca Cola 500ml")

    @supplier_import = create(:supplier_import, account: @account, supplier: @supplier)
    @supplier_import.file.attach(
      io: StringIO.new("nombre,precio\nCOCA COLA 500ML,3.50\n"),
      filename: "test.csv",
      content_type: "text/csv"
    )
  end

  teardown { teardown_tenant }

  test "se encola en el queue por defecto" do
    assert_enqueued_with(job: SupplierImportJob, args: [ @supplier_import.id ]) do
      SupplierImportJob.perform_later(@supplier_import.id)
    end
  end

  test "procesa el import sin necesitar un tenant seteado de antemano" do
    teardown_tenant # simula el contexto real de un job: sin tenant al arrancar

    SupplierImportJob.perform_now(@supplier_import.id)

    setup_tenant(@account)
    assert @supplier_import.reload.completed?
    assert_equal 1, Resolution.count
  end

  test "no filtra datos de otro tenant al buscar el supplier_import" do
    other_account = create(:account)
    other_import = ActsAsTenant.with_tenant(other_account) do
      other_supplier = create(:supplier, account: other_account)
      import = create(:supplier_import, account: other_account, supplier: other_supplier)
      import.file.attach(
        io: StringIO.new("nombre,precio\nAlgo,1.00\n"),
        filename: "test.csv",
        content_type: "text/csv"
      )
      import
    end

    teardown_tenant
    SupplierImportJob.perform_now(other_import.id)

    ActsAsTenant.with_tenant(other_account) { assert other_import.reload.completed? }
  end
end
