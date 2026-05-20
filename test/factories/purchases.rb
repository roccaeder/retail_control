FactoryBot.define do
  factory :purchase do
    association :account
    association :supplier
    total  { 0 }
    status { :draft }

    trait :with_item do
      after(:create) do |purchase|
        product = create(:product, account: purchase.account)
        create(:purchase_item, purchase: purchase, product: product, account: purchase.account,
               quantity: 5, unit_cost: 2.50)
      end
    end
  end

  factory :purchase_item do
    association :account
    association :purchase
    association :product
    quantity  { 5 }
    unit_cost { 2.50 }
  end
end
