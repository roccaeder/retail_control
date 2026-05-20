class StockMovement < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :product
  belongs_to :origin, polymorphic: true, optional: true

  enum :movement_type, { sale: 0, purchase: 1, adjustment: 2, waste: 3 }

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :movement_type, presence: true
end
