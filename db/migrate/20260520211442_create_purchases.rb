class CreatePurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :purchases do |t|
      t.references :account,  null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.string  :invoice_number
      t.decimal :total, precision: 10, scale: 2, default: 0
      t.date    :received_date
      t.integer :status, null: false, default: 0
      t.timestamps
    end
  end
end
