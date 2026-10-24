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

ActiveRecord::Schema[7.2].define(version: 2026_10_22_033000) do
  create_table "account_observations", force: :cascade do |t|
    t.integer "account_id", null: false
    t.date "observed_on", null: false
    t.integer "sequence", default: 1, null: false
    t.decimal "amount", precision: 16, scale: 2, null: false
    t.text "notes"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "observed_on", "sequence"], name: "index_account_observations_on_subject_and_sequence", unique: true
    t.index ["account_id"], name: "index_account_observations_on_account_id"
    t.index ["created_by_id"], name: "index_account_observations_on_created_by_id"
    t.index ["updated_by_id"], name: "index_account_observations_on_updated_by_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "account_type", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "expense_categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_expense_categories_on_name", unique: true
  end

  create_table "expenses", force: :cascade do |t|
    t.string "kind", default: "spending", null: false
    t.decimal "amount", precision: 16, scale: 2, null: false
    t.date "spent_on", null: false
    t.integer "expense_category_id"
    t.string "merchant"
    t.text "notes"
    t.integer "refund_of_id"
    t.integer "source_account_id"
    t.integer "destination_account_id"
    t.integer "import_batch_id"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_expenses_on_created_by_id"
    t.index ["destination_account_id"], name: "index_expenses_on_destination_account_id"
    t.index ["expense_category_id"], name: "index_expenses_on_expense_category_id"
    t.index ["import_batch_id"], name: "index_expenses_on_import_batch_id"
    t.index ["refund_of_id"], name: "index_expenses_on_refund_of_id"
    t.index ["source_account_id"], name: "index_expenses_on_source_account_id"
    t.index ["spent_on"], name: "index_expenses_on_spent_on"
    t.index ["updated_by_id"], name: "index_expenses_on_updated_by_id"
  end

  create_table "financial_decisions", force: :cascade do |t|
    t.date "decided_on", null: false
    t.text "description", null: false
    t.text "rationale", null: false
    t.text "alternatives", null: false
    t.text "expected_effect", null: false
    t.date "review_on"
    t.text "outcome"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_financial_decisions_on_created_by_id"
    t.index ["updated_by_id"], name: "index_financial_decisions_on_updated_by_id"
  end

  create_table "financial_reviews", force: :cascade do |t|
    t.date "review_on", null: false
    t.text "commentary", null: false
    t.string "calculation_version", null: false
    t.json "inputs", null: false
    t.json "record_references", null: false
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_financial_reviews_on_created_by_id"
  end

  create_table "import_batches", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "status", default: "imported", null: false
    t.json "column_mapping"
    t.string "original_filename"
    t.datetime "reversed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_import_batches_on_user_id"
  end

  create_table "market_prices", force: :cascade do |t|
    t.integer "security_id", null: false
    t.decimal "amount", precision: 16, scale: 6, null: false
    t.string "currency", default: "USD", null: false
    t.date "market_on", null: false
    t.datetime "retrieved_at", null: false
    t.string "source", null: false
    t.integer "entered_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entered_by_id"], name: "index_market_prices_on_entered_by_id"
    t.index ["security_id", "market_on"], name: "index_market_prices_on_security_id_and_market_on"
    t.index ["security_id"], name: "index_market_prices_on_security_id"
  end

  create_table "position_observations", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "security_id", null: false
    t.date "observed_on", null: false
    t.integer "sequence", default: 1, null: false
    t.decimal "quantity", precision: 20, scale: 8, null: false
    t.decimal "cost_basis", precision: 16, scale: 2, default: "0.0", null: false
    t.text "notes"
    t.string "reason"
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "security_id", "observed_on", "sequence"], name: "index_position_observations_on_subject_and_sequence", unique: true
    t.index ["account_id"], name: "index_position_observations_on_account_id"
    t.index ["created_by_id"], name: "index_position_observations_on_created_by_id"
    t.index ["security_id"], name: "index_position_observations_on_security_id"
    t.index ["updated_by_id"], name: "index_position_observations_on_updated_by_id"
  end

  create_table "record_revisions", force: :cascade do |t|
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "revision_number", null: false
    t.json "previous_values", null: false
    t.json "new_values", null: false
    t.integer "user_id"
    t.text "reason"
    t.datetime "created_at", null: false
    t.index ["record_type", "record_id", "revision_number"], name: "index_record_revisions_on_record_and_number", unique: true
    t.index ["record_type", "record_id"], name: "index_record_revisions_on_record"
    t.index ["user_id"], name: "index_record_revisions_on_user_id"
  end

  create_table "recurring_items", force: :cascade do |t|
    t.string "name", null: false
    t.string "direction", null: false
    t.decimal "amount", precision: 16, scale: 2, null: false
    t.string "frequency", null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.string "treatment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "savings_goals", force: :cascade do |t|
    t.decimal "amount", precision: 16, scale: 2, null: false
    t.date "starts_on", null: false
    t.date "ends_on"
    t.text "reason", null: false
    t.date "review_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "securities", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "identifier", null: false
    t.string "currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_securities_on_ticker", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "appearance", default: "system", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "account_observations", "accounts"
  add_foreign_key "account_observations", "users", column: "created_by_id"
  add_foreign_key "account_observations", "users", column: "updated_by_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "expenses", "accounts", column: "destination_account_id"
  add_foreign_key "expenses", "accounts", column: "source_account_id"
  add_foreign_key "expenses", "expense_categories"
  add_foreign_key "expenses", "expenses", column: "refund_of_id"
  add_foreign_key "expenses", "import_batches"
  add_foreign_key "expenses", "users", column: "created_by_id"
  add_foreign_key "expenses", "users", column: "updated_by_id"
  add_foreign_key "financial_decisions", "users", column: "created_by_id"
  add_foreign_key "financial_decisions", "users", column: "updated_by_id"
  add_foreign_key "financial_reviews", "users", column: "created_by_id"
  add_foreign_key "import_batches", "users"
  add_foreign_key "market_prices", "securities"
  add_foreign_key "market_prices", "users", column: "entered_by_id"
  add_foreign_key "position_observations", "accounts"
  add_foreign_key "position_observations", "securities"
  add_foreign_key "position_observations", "users", column: "created_by_id"
  add_foreign_key "position_observations", "users", column: "updated_by_id"
  add_foreign_key "record_revisions", "users"
  add_foreign_key "sessions", "users"
end
