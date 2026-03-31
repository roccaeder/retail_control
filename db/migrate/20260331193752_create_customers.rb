class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name
      t.string :phone
      t.decimal :debt_limit, precision: 10, scale: 2, default: 0.0
      t.decimal :current_debt, precision: 10, scale: 2, default: 0.0

      t.timestamps
    end
  end
end
