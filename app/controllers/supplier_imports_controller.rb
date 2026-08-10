class SupplierImportsController < ApplicationController
  layout "erp"

  before_action :set_supplier_import, only: [ :show ]

  def index
    @supplier_imports = SupplierImport.includes(:supplier).order(created_at: :desc)
  end

  def new
    @supplier_import = SupplierImport.new
    load_form_data
  end

  def create
    @supplier_import = SupplierImport.new(supplier_import_params)
    @supplier_import.account = current_tenant

    if @supplier_import.save
      SupplierImportJob.perform_later(@supplier_import.id)
      redirect_to supplier_imports_path, notice: "Archivo recibido. Procesando en segundo plano."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  private

  def set_supplier_import
    @supplier_import = SupplierImport.find(params[:id])
  end

  def supplier_import_params
    params.require(:supplier_import).permit(:supplier_id, :file)
  end

  def load_form_data
    @suppliers = Supplier.order(:name)
  end
end
