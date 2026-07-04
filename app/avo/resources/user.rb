class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :email, as: :text, required: true
    field :password, as: :password, required: true, visible: true
    field :password_confirmation, as: :password, required: true, visible: true
    field :account, as: :belongs_to, required: true
  end
end
