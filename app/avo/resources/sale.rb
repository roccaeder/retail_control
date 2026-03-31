class Avo::Resources::Sale < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :customer_id, as: :number
    field :subtotal, as: :number
    field :discount_amount, as: :number
    field :total, as: :number
    field :status, as: :number
    field :payment_method, as: :number
    field :customer, as: :belongs_to
  end
end
