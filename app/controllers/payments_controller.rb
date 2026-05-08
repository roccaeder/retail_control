class PaymentsController < ApplicationController
  layout "erp"

  before_action :set_sale

  def new
    @payment = Payment.new
  end

  def create
    result = Payments::RegisterPaymentService.call(
      sale:           @sale,
      amount:         payment_params[:amount],
      payment_method: payment_params[:payment_method],
      date:           Date.current
    )

    if result.success
      @sale.reload
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("modal", ""),
            turbo_stream.replace("sale-row-#{@sale.id}",
              partial: "sales/sale_row", locals: { sale: @sale })
          ]
        end
        format.html { redirect_to sales_path, notice: "Pago registrado correctamente." }
      end
    else
      @payment = Payment.new
      @errors  = result.errors
      render :new, status: :unprocessable_entity, formats: [ :html ]
    end
  end

  private

  def set_sale
    @sale = Sale.find(params[:sale_id])
  end

  def payment_params
    params.require(:payment).permit(:amount, :payment_method)
  end
end
