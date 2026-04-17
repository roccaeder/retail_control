FactoryBot.define do
  factory :user do
    association :account
    sequence(:email) { |n| "user#{n}@example.com" }
    password              { "password123" }
    password_confirmation { "password123" }
  end
end
