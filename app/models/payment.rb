class Payment < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :sale

  enum :payment_method, { cash: 0, credit: 1, transfer: 2 }

  validates :amount, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :payment_method, presence: true

  after_create :sync_sale_and_customer_debt

  private

  def sync_sale_and_customer_debt
    Payments::RegisterPaymentService.sync_after_payment(self)
  end
end
