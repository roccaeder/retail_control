class SuppliersController < ApplicationController
  layout "erp"

  before_action :set_supplier, only: [ :show, :edit, :update, :destroy ]

  def index
    @suppliers = Supplier.order(:name)
  end

  def show
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)
    @supplier.account = current_tenant
    if @supplier.save
      redirect_to suppliers_path, notice: "Proveedor creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to suppliers_path, notice: "Proveedor actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.destroy
    redirect_to suppliers_path, notice: "Proveedor eliminado."
  rescue ActiveRecord::DeleteRestrictionError
    redirect_to suppliers_path, alert: "No se puede eliminar: tiene compras asociadas."
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(:name, :ruc_or_nit, :phone, :email)
  end
end
