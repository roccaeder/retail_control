class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :account,  null: false, foreign_key: true
      t.references :supplier, null: true,  foreign_key: true
      t.string  :category,    null: false
      t.decimal :amount,      precision: 10, scale: 2, null: false
      t.date    :date,        null: false
      t.string  :description
      t.string  :payable_type
      t.bigint  :payable_id
      t.timestamps
    end
    add_index :expenses, [ :account_id, :date ]
  end
end
