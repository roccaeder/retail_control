class AddTrigramIndexToProducts < ActiveRecord::Migration[8.1]
  def change
    add_index :products, :name,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_products_on_name_trigram"
  end
end
