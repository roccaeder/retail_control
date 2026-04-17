FactoryBot.define do
  factory :payment do
    association :account
    association :sale
    amount         { 5.00 }
    payment_method { :cash }
    date           { Date.today }
  end
end
