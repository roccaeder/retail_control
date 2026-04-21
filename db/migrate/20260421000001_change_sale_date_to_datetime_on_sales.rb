class ChangeSaleDateToDatetimeOnSales < ActiveRecord::Migration[8.1]
  def up
    change_column :sales, :sale_date, :datetime
  end

  def down
    change_column :sales, :sale_date, :date
  end
end
