class SalesController < ApplicationController
  before_action :authenticate_user!
  layout "erp"

  def index
    @sales = Sale.includes(:customer).order(created_at: :desc)
  end

  def new
    @customers = Customer.order(:name)
    @products = Product.where("stock > 0").order(:name)
  end

  def create
    @sale = Sale.new(sale_params)

    subtotal = @sale.sale_items.sum { |item| item.quantity.to_i * item.unit_price.to_f }
    discount = @sale.discount_amount.to_f
    @sale.subtotal = subtotal
    @sale.total    = [ subtotal - discount, 0 ].max

    if @sale.sale_items.empty?
      flash.now[:alert] = "Agrega al menos un producto para registrar la venta."
      @customers = Customer.order(:name)
      @products  = Product.where("stock > 0").order(:name)
      render :new, status: :unprocessable_entity
      return
    end

    if @sale.save
      redirect_to sales_path, notice: "Venta ##{@sale.id} registrada correctamente."
    else
      @customers = Customer.order(:name)
      @products  = Product.where("stock > 0").order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def sale_params
    params.require(:sale).permit(
      :customer_id, :status, :payment_method, :discount_amount,
      sale_items_attributes: [ :product_id, :quantity, :unit_price, :discount ]
    )
  end
end
