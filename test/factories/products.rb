FactoryBot.define do
  factory :product do
    association :account
    sequence(:name) { |n| "Producto #{n}" }
    sequence(:sku)  { |n| "AUTO-SKU-#{n.to_s.rjust(3, '0')}" }
    cost_price { 1.00 }
    sale_price { 1.50 }
    stock      { 50 }
  end
end
