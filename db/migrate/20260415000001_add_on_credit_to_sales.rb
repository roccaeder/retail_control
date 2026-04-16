class AddOnCreditToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :on_credit, :boolean, default: false, null: false
  end
end
