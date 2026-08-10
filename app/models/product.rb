class Product < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  has_many :sale_items, dependent: :restrict_with_error
  has_many :stock_movements, dependent: :destroy
  has_many :resolutions, dependent: :nullify

  scope :search, ->(q) {
    q.present? ? where("name ILIKE ? OR sku ILIKE ?", "%#{q}%", "%#{q}%") : all
  }

  validates :name, presence: true
  validates :sale_price, numericality: { greater_than_or_equal_to: 0 }
  validates :cost_price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { scope: :account_id }, allow_blank: true
end
