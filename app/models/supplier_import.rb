class SupplierImport < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account
  belongs_to :supplier
  has_many :resolutions, dependent: :destroy
  has_one_attached :file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :file, presence: true, on: :create
end
