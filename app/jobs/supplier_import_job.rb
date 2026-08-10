class SupplierImportJob < ApplicationJob
  queue_as :default

  def perform(supplier_import_id)
    # acts_as_tenant scopes finds to the current tenant, which isn't set yet
    # in a job's execution context — unscoped so we can look the record up
    # and find out which account it belongs to in the first place.
    supplier_import = SupplierImport.unscoped.find(supplier_import_id)

    ActsAsTenant.with_tenant(supplier_import.account) do
      SupplierImports::ProcessImportService.call(supplier_import:)
    end
  end
end
