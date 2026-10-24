class CreateHouseholdFinance < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email_address, unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.timestamps
    end

    create_table :accounts do |t|
      t.string :name, null: false
      t.string :account_type, null: false
      t.string :currency, null: false, default: "USD"
      t.datetime :archived_at
      t.timestamps
    end

    create_table :securities do |t|
      t.string :ticker, null: false
      t.string :identifier, null: false
      t.string :currency, null: false, default: "USD"
      t.timestamps
    end
    add_index :securities, :ticker, unique: true

    create_table :account_observations do |t|
      t.references :account, null: false, foreign_key: true
      t.date :observed_on, null: false
      t.integer :sequence, null: false, default: 1
      t.decimal :amount, precision: 16, scale: 2, null: false
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :account_observations, [ :account_id, :observed_on, :sequence ], unique: true, name: "index_account_observations_on_subject_and_sequence"

    create_table :position_observations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :security, null: false, foreign_key: true
      t.date :observed_on, null: false
      t.integer :sequence, null: false, default: 1
      t.decimal :quantity, precision: 20, scale: 8, null: false
      t.decimal :cost_basis, precision: 16, scale: 2, null: false, default: 0
      t.text :notes
      t.string :reason
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :position_observations, [ :account_id, :security_id, :observed_on, :sequence ], unique: true, name: "index_position_observations_on_subject_and_sequence"

    create_table :record_revisions do |t|
      t.references :record, polymorphic: true, null: false
      t.integer :revision_number, null: false
      t.json :previous_values, null: false
      t.json :new_values, null: false
      t.references :user, foreign_key: true
      t.text :reason
      t.datetime :created_at, null: false
    end
    add_index :record_revisions, [ :record_type, :record_id, :revision_number ], unique: true, name: "index_record_revisions_on_record_and_number"

    create_table :market_prices do |t|
      t.references :security, null: false, foreign_key: true
      t.decimal :amount, precision: 16, scale: 6, null: false
      t.string :currency, null: false, default: "USD"
      t.date :market_on, null: false
      t.datetime :retrieved_at, null: false
      t.string :source, null: false
      t.references :entered_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :market_prices, [ :security_id, :market_on ]

    create_table :expense_categories do |t|
      t.string :name, null: false
      t.timestamps
    end
    add_index :expense_categories, :name, unique: true

    create_table :import_batches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "imported"
      t.json :column_mapping
      t.string :original_filename
      t.datetime :reversed_at
      t.timestamps
    end

    create_table :expenses do |t|
      t.string :kind, null: false, default: "spending"
      t.decimal :amount, precision: 16, scale: 2, null: false
      t.date :spent_on, null: false
      t.references :expense_category, foreign_key: true
      t.string :merchant
      t.text :notes
      t.references :refund_of, foreign_key: { to_table: :expenses }
      t.references :source_account, foreign_key: { to_table: :accounts }
      t.references :destination_account, foreign_key: { to_table: :accounts }
      t.references :import_batch, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :expenses, :spent_on

    create_table :recurring_items do |t|
      t.string :name, null: false
      t.string :direction, null: false
      t.decimal :amount, precision: 16, scale: 2, null: false
      t.string :frequency, null: false
      t.date :starts_on, null: false
      t.date :ends_on
      t.string :treatment, null: false
      t.timestamps
    end

    create_table :savings_goals do |t|
      t.decimal :amount, precision: 16, scale: 2, null: false
      t.date :starts_on, null: false
      t.date :ends_on
      t.text :reason, null: false
      t.date :review_on
      t.timestamps
    end

    create_table :financial_decisions do |t|
      t.date :decided_on, null: false
      t.text :description, null: false
      t.text :rationale, null: false
      t.text :alternatives, null: false
      t.text :expected_effect, null: false
      t.date :review_on
      t.text :outcome
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :financial_reviews do |t|
      t.date :review_on, null: false
      t.text :commentary, null: false
      t.string :calculation_version, null: false
      t.json :inputs, null: false
      t.json :record_references, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    create_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, null: false
      t.index [ :key ], unique: true
    end

    create_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.references :record, null: false, polymorphic: true, index: false
      t.references :blob, null: false
      t.datetime :created_at, null: false
      t.index [ :record_type, :record_id, :name, :blob_id ], name: "index_active_storage_attachments_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records do |t|
      t.belongs_to :blob, null: false, index: false
      t.string :variation_digest, null: false
      t.index [ :blob_id, :variation_digest ], name: "index_active_storage_variant_records_uniqueness", unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
