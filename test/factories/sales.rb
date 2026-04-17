FactoryBot.define do
  factory :sale do
    association :account
    # customer debe pertenecer a la misma cuenta
    after(:build) do |sale|
      sale.customer ||= build(:customer, account: sale.account)
    end

    sequence(:code) { |n| "VTA-#{n.to_s.rjust(4, '0')}" }
    payment_method  { :cash }
    on_credit       { false }
    discount_amount { 0.00 }
    subtotal        { 10.00 }
    total           { 10.00 }
    status          { :paid }

    trait :pending do
      on_credit      { true }
      payment_method { :credit }
      status         { :pending }
    end

    trait :partial do
      on_credit      { true }
      payment_method { :credit }
      status         { :partial }
      total          { 10.00 }
    end

    trait :with_item do
      after(:create) do |sale|
        product = create(:product, account: sale.account)
        create(:sale_item, sale: sale, product: product, account: sale.account)
      end
    end
  end
end
