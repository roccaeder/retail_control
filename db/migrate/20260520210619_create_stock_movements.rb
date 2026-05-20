class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :movement_type, null: false
      t.references :origin, polymorphic: true, null: true
      t.string :description
      t.timestamps
    end
    add_index :stock_movements, [ :account_id, :product_id ]
  end
end
