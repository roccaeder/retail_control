class SalesController < ApplicationController
  layout "erp"

  before_action :set_sale, only: [ :show ]

  def index
    @sales = Sale.includes(:customer, :payments).order(created_at: :desc)
  end

  def show
    @payments = @sale.payments.order(:date)
  end

  def new
    @sale = Sale.new
    load_form_data
  end

  def create
    @sale = Sale.new(sale_params)

    calculate_totals
    @sale.account = current_tenant

    if @sale.sale_items.empty?
      @sale.errors.add(:base, "Agrega al menos un producto para registrar la venta.")
      load_form_data
      render :new, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      @sale.save!
      register_initial_payment
    end

    redirect_to sales_path, notice: "Venta #{@sale.code} registrada correctamente."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :new, status: :unprocessable_entity
  end

  private

  def set_sale
    # acts_as_tenant garantiza que solo se encuentra dentro del tenant actual.
    @sale = Sale.find(params[:id])
  end

  def sale_params
    params.require(:sale).permit(
      :customer_id, :payment_method, :on_credit, :discount_amount,
      sale_items_attributes: [ :product_id, :quantity, :unit_price, :discount ]
    )
  end

  def calculate_totals
    subtotal = @sale.sale_items.sum { |item| item.quantity.to_i * item.unit_price.to_f }
    discount = @sale.discount_amount.to_f
    @sale.subtotal = subtotal
    @sale.total    = [ subtotal - discount, 0 ].max
  end

  def register_initial_payment
    result = Payments::RegisterPaymentService.call(
      sale:           @sale,
      amount:         @sale.total,
      payment_method: @sale.payment_method,
      date:           Date.current
    )

    raise ActiveRecord::RecordInvalid.new(@sale) unless result.success
  end

  def load_form_data
    @customers = Customer.order(:name)
    @products  = Product.where("stock > 0").order(:name)
  end
end
