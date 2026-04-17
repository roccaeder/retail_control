FactoryBot.define do
  factory :customer do
    association :account
    sequence(:name) { |n| "Cliente #{n}" }
    phone        { "91234567" }
    debt_limit   { 1000.00 }
    current_debt { 0.00 }
  end
end
