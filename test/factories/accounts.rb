FactoryBot.define do
  factory :account do
    sequence(:name)      { |n| "Tienda #{n}" }
    sequence(:subdomain) { |n| "tienda-#{n}" }
  end
end
