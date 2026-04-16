class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :sales, dependent: :destroy
  has_many :sale_items, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "solo letras minúsculas, números y guiones" }
end
