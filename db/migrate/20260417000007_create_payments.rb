class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :sale, null: false, foreign_key: true, index: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :payment_method, null: false
      t.date :date, null: false

      t.timestamps
    end
  end
end
