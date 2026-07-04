class Avo::Resources::Account < Avo::BaseResource
  self.icon = "tabler/outline/user-circle"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :name, as: :text
    field :subdomain, as: :text
    field :users, as: :has_many
    field :customers, as: :has_many
    field :products, as: :has_many
    field :sales, as: :has_many
    field :sale_items, as: :has_many
    field :payments, as: :has_many
  end
end
