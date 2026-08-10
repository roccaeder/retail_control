FactoryBot.define do
  factory :supplier_import do
    association :account
    association :supplier
    status { :pending }

    after(:build) do |supplier_import|
      supplier_import.file.attach(
        io: StringIO.new("name,price\nCoca Cola 500ml,3.50\n"),
        filename: "supplier_products.csv",
        content_type: "text/csv"
      )
    end
  end
end
