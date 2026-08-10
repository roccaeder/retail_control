class CreateSupplierImports < ActiveRecord::Migration[8.1]
  def change
    create_table :supplier_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :total_rows, null: false, default: 0
      t.integer :auto_matched_count, null: false, default: 0
      t.integer :needs_review_count, null: false, default: 0
      t.integer :unmatched_count, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :supplier_imports, [ :account_id, :status ]
  end
end
