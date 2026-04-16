class AddAccountIdAndCodeToSales < ActiveRecord::Migration[8.1]
  def change
    add_reference :sales, :account, null: true, foreign_key: true, index: true
    add_column :sales, :code, :string

    # Índice compuesto único: el código es único dentro de cada cuenta
    add_index :sales, [ :account_id, :code ], unique: true, name: "index_sales_on_account_id_and_code"
  end
end
