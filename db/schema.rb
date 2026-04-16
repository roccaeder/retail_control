# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_17_000008) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_accounts_on_subdomain", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "current_debt", precision: 10, scale: 2, default: "0.0"
    t.decimal "debt_limit", precision: 10, scale: 2, default: "0.0"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_customers_on_account_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "payment_method", null: false
    t.bigint "sale_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["sale_id"], name: "index_payments_on_sale_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "cost_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "created_at", null: false
    t.string "name"
    t.decimal "sale_price", precision: 10, scale: 2, default: "0.0"
    t.string "sku"
    t.integer "stock"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_products_on_account_id"
  end

  create_table "sale_items", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.bigint "sale_id", null: false
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sale_items_on_account_id"
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.boolean "on_credit", default: false, null: false
    t.integer "payment_method"
    t.integer "status"
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "total", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["account_id", "code"], name: "index_sales_on_account_id_and_code", unique: true
    t.index ["account_id"], name: "index_sales_on_account_id"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "customers", "accounts"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "sales"
  add_foreign_key "products", "accounts"
  add_foreign_key "sale_items", "accounts"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "accounts"
  add_foreign_key "sales", "customers"
  add_foreign_key "users", "accounts"
end
