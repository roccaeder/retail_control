class Expense < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :supplier, optional: true
  belongs_to :payable, polymorphic: true, optional: true

  validates :category,    presence: true
  validates :amount,      numericality: { greater_than: 0 }
  validates :date,        presence: true
end
