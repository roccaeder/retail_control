class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.references :customer, null: false, foreign_key: true
      t.decimal :subtotal, precision: 10, scale: 2, default: 0.0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.0
      t.decimal :total, precision: 10, scale: 2, default: 0.0
      t.integer :status
      t.integer :payment_method

      t.timestamps
    end
  end
end
