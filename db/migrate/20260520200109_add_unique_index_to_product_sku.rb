class AddUniqueIndexToProductSku < ActiveRecord::Migration[8.1]
  def change
    remove_index :products, :sku, if_exists: true
    add_index :products, [ :account_id, :sku ], unique: true,
              where: "sku IS NOT NULL AND sku != ''",
              name: "index_products_on_account_id_and_sku"
  end
end
