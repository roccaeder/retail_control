class Customer < ApplicationRecord
  acts_as_tenant(:account)

  has_many :sales, dependent: :restrict_with_error

  validates :name, presence: true
  validates :debt_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :current_debt, numericality: { greater_than_or_equal_to: 0 }

  def within_debt_limit?
    current_debt <= debt_limit
  end
end
