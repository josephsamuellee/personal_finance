class AddKindToImportBatches < ActiveRecord::Migration[7.2]
  def change
    add_column :import_batches, :kind, :string, default: "expenses", null: false
    add_reference :import_batches, :account, foreign_key: true
  end
end
