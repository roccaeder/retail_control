class AddSaleDateToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :sale_date, :date
  end
end
