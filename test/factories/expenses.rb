FactoryBot.define do
  factory :expense do
    association :account
    category    { "Servicios" }
    amount      { 50.00 }
    date        { Date.current }
    description { "Pago de servicio" }
  end
end
