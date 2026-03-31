class Sale < ApplicationRecord
  belongs_to :customer
  has_many :sale_items, dependent: :destroy

  enum :status, { paid: 0, pending: 1 }
  enum :payment_method, { cash: 0, credit: 1, transfer: 2 }
end