class SaleItem < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :sale
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def subtotal
    (quantity * unit_price) - discount
  end
end
