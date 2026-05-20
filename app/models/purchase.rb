class Purchase < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :supplier
  has_many :purchase_items, dependent: :destroy
  has_many :products, through: :purchase_items

  accepts_nested_attributes_for :purchase_items, reject_if: :all_blank

  enum :status, { draft: 0, received: 1, cancelled: 2 }

  validates :supplier, presence: true
  validates :total, numericality: { greater_than_or_equal_to: 0 }
end
