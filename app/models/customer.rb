class Customer < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  has_many :sales, dependent: :restrict_with_error

  scope :search, ->(q) {
    q.present? ? where("name ILIKE ? OR phone ILIKE ?", "%#{q}%", "%#{q}%") : all
  }

  validates :name, presence: true
  validates :debt_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :current_debt, numericality: { greater_than_or_equal_to: 0 }

  def within_debt_limit?
    current_debt <= debt_limit
  end

  def generic?
    name == "Consumidor Final"
  end
end
