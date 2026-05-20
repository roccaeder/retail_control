class PurchasesController < ApplicationController
  layout "erp"

  before_action :set_purchase, only: [ :show, :receive ]

  def index
    @purchases = Purchase.includes(:supplier)
                         .order(created_at: :desc)
  end

  def show
  end

  def new
    @purchase = Purchase.new
    @purchase.purchase_items.build
    load_form_data
  end

  def create
    @purchase = Purchase.new(purchase_params)
    @purchase.account = current_tenant
    if @purchase.save
      redirect_to purchases_path, notice: "Compra registrada en borrador."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def receive
    result = Purchases::ProcessPurchaseService.call(purchase: @purchase)
    if result.success
      redirect_to purchases_path, notice: "Compra recibida. Stock actualizado."
    else
      redirect_to purchases_path, alert: result.errors.join(", ")
    end
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase).permit(
      :supplier_id, :invoice_number,
      purchase_items_attributes: [ :product_id, :quantity, :unit_cost ]
    )
  end

  def load_form_data
    @suppliers = Supplier.order(:name)
    @products  = Product.order(:name)
  end
end
