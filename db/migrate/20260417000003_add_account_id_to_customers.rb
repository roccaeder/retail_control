class AddAccountIdToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_reference :customers, :account, null: true, foreign_key: true, index: true
  end
end
