class CreateResolutions < ActiveRecord::Migration[8.1]
  def change
    create_table :resolutions do |t|
      t.references :account, null: false, foreign_key: true
      t.references :supplier_import, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }

      t.jsonb :raw_row, null: false, default: {}
      t.string :raw_name, null: false
      t.string :normalized_name, null: false

      # Winning match, if any (mirrors the best entry in `candidates`).
      t.integer :strategy
      t.float :score

      # Top-N candidates considered, each { product_id:, score:, strategy: },
      # highest score first. Kept even for the winner so recall@k can be
      # computed later without re-running the matcher.
      t.jsonb :candidates, null: false, default: []

      t.integer :status, null: false
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :resolutions, [ :supplier_import_id, :status ]
  end
end
