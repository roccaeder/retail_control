class SetAccountIdNotNull < ActiveRecord::Migration[8.1]
  def up
    # Verificación de seguridad: abortar si quedan NULLs sin poblar
    %i[users customers products sales sale_items].each do |table|
      count = execute("SELECT COUNT(*) FROM #{table} WHERE account_id IS NULL").first["count"].to_i
      raise "Aún hay #{count} filas con account_id NULL en #{table}. Poblalas antes de correr esta migración." if count > 0
    end

    change_column_null :users,      :account_id, false
    change_column_null :customers,  :account_id, false
    change_column_null :products,   :account_id, false
    change_column_null :sales,      :account_id, false
    change_column_null :sale_items, :account_id, false
  end

  def down
    change_column_null :users,      :account_id, true
    change_column_null :customers,  :account_id, true
    change_column_null :products,   :account_id, true
    change_column_null :sales,      :account_id, true
    change_column_null :sale_items, :account_id, true
  end
end
