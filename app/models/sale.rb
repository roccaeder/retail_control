class Sale < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :customer
  has_many :sale_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  accepts_nested_attributes_for :sale_items, reject_if: :all_blank

  # pending: aún no se pagó nada, partial: pago parcial, paid: saldado
  enum :status, { paid: 0, pending: 1, partial: 2 }
  enum :payment_method, { cash: 0, credit: 1, transfer: 2 }

  validates :code, uniqueness: { scope: :account_id }, allow_blank: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }

  before_validation :auto_set_status
  before_create :generate_code
  before_create :set_sale_date

  def balance_due
    (total - payments.sum(:amount)).round(2)
  end

  private

  def auto_set_status
    self.status = on_credit? ? :pending : :paid
  end

  def generate_code
    return if code.present?

    last_number = Sale.where(account_id: account_id)
                      .where("code ~ ?", "^VTA-[0-9]+$")
                      .maximum("CAST(SUBSTRING(code FROM 5) AS INTEGER)") || 0
    self.code = "VTA-#{(last_number + 1).to_s.rjust(4, '0')}"
  end
  
  def set_sale_date
    self.sale_date ||= Date.current
  end
end
