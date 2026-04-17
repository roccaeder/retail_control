FactoryBot.define do
  factory :sale_item do
    association :account
    association :sale
    association :product
    quantity   { 2 }
    unit_price { 1.50 }
    discount   { 0.00 }
  end
end
