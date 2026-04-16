class AddAccountIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :account, null: true, foreign_key: true, index: true

    # Una vez poblada la columna, reforzar NOT NULL:
    # UPDATE users SET account_id = <default_account_id> WHERE account_id IS NULL;
    # change_column_null :users, :account_id, false
  end
end
