class User < ApplicationRecord
  acts_as_tenant(:account)

  belongs_to :account

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
