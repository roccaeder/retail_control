class Avo::Resources::SaleItem < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :sale, as: :belongs_to
    field :product, as: :belongs_to
    field :quantity, as: :number
    field :unit_price, as: :number
    field :discount, as: :number
  end
end
