class CreateSuppliers < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :ruc_or_nit
      t.string :phone
      t.string :email
      t.timestamps
    end
  end
end
