class Supplier < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  has_many :purchases, dependent: :restrict_with_exception
  has_many :supplier_imports, dependent: :restrict_with_exception

  validates :name, presence: true
end
