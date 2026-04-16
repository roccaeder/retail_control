module Payments
  class RegisterPaymentService
    Result = Data.define(:success, :payment, :errors)

    # Punto de entrada principal: crea el pago y sincroniza estado/deuda.
    def self.call(sale:, amount:, payment_method:, date: Date.current)
      new(sale:, amount:, payment_method:, date:).call
    end

    # Llamado desde el callback after_create de Payment para no duplicar lógica.
    def self.sync_after_payment(payment)
      new_instance = new(sale: payment.sale, amount: 0, payment_method: payment.payment_method, date: payment.date)
      new_instance.send(:update_sale_status, payment.sale)
      new_instance.send(:update_customer_debt, payment.sale.customer)
    end

    def initialize(sale:, amount:, payment_method:, date:)
      @sale           = sale
      @amount         = amount.to_d
      @payment_method = payment_method
      @date           = date
    end

    def call
      ActiveRecord::Base.transaction do
        payment = @sale.payments.create!(
          amount:         @amount,
          payment_method: @payment_method,
          date:           @date,
          account:        @sale.account
        )
        # after_create en Payment ya llama sync_after_payment, pero lo invocamos
        # aquí también para devolver el resultado en la misma transacción.
        Result.new(success: true, payment:, errors: [])
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, payment: nil, errors: e.record.errors.full_messages)
    end

    private

    def update_sale_status(sale)
      balance = sale.reload.balance_due

      new_status = if balance <= 0
                     :paid
      elsif balance < sale.total
                     :partial
      else
                     :pending
      end

      # Evitar el callback auto_set_status (que depende de on_credit) al actualizar status.
      sale.update_column(:status, Sale.statuses[new_status])
    end

    def update_customer_debt(customer)
      # Suma todos los saldos pendientes del cliente dentro del tenant actual.
      open_sales = Sale.where(customer:).where(status: [ :pending, :partial ])
      total_debt = open_sales.sum { |s| s.balance_due }
      customer.update_column(:current_debt, total_debt)
    end
  end
end
