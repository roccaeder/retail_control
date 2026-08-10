FactoryBot.define do
  factory :resolution do
    association :account
    association :supplier_import

    raw_row { { "name" => "Coca Cola 500ml", "price" => "3.50" } }
    raw_name { "Coca Cola 500ml" }
    normalized_name { "coca cola 500 ml" }
    status { :needs_review }
    candidates { [] }
  end
end
