class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :sku
      t.decimal :sale_price, precision: 10, scale: 2, default: 0.0
      t.decimal :cost_price, precision: 10, scale: 2, default: 0.0
      t.integer :stock

      t.timestamps
    end
  end
end
