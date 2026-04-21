FactoryBot.define do
  factory :sale do
    association :account
    after(:build) do |sale|
      sale.customer ||= create(:customer, account: sale.account)
      if sale.sale_items.empty?
        sale.sale_items.build(
          product:    build(:product, account: sale.account),
          quantity:   1,
          unit_price: 10.0,
          discount:   0.0,
          account:    sale.account
        )
      end
    end

    sequence(:code) { |n| "VTA-#{n.to_s.rjust(4, '0')}" }
    payment_method  { :cash }
    on_credit       { false }
    discount_amount { 0.00 }
    subtotal        { 10.00 }
    total           { 10.00 }
    status          { :paid }

    trait :pending do
      on_credit       { true }
      payment_method  { :credit }
      status          { :pending }
      amount_received { 5.0 }
    end

    trait :partial do
      on_credit       { true }
      payment_method  { :credit }
      total           { 10.00 }
      amount_received { 5.0 }
      after(:create) { |sale| sale.update_column(:status, Sale.statuses[:partial]) }
    end

    trait :with_item do
      after(:create) do |sale|
        product = create(:product, account: sale.account)
        create(:sale_item, sale: sale, product: product, account: sale.account)
      end
    end
  end
end
