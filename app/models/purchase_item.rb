class PurchaseItem < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :purchase
  belongs_to :product

  validates :quantity,  numericality: { greater_than: 0, only_integer: true }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
end
