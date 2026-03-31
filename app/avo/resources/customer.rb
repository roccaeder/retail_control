class Avo::Resources::Customer < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :phone, as: :text
    field :debt_limit, as: :number
    field :current_debt, as: :number
  end
end
