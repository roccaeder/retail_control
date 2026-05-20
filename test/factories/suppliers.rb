FactoryBot.define do
  factory :supplier do
    association :account
    sequence(:name) { |n| "Proveedor #{n}" }
    phone { "555-000#{rand(100)}" }
  end
end
