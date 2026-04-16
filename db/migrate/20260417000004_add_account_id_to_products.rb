class AddAccountIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :account, null: true, foreign_key: true, index: true
  end
end
