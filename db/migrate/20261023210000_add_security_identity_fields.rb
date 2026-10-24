class AddSecurityIdentityFields < ActiveRecord::Migration[7.2]
  def up
    add_column :securities, :note, :text
    add_column :securities, :exchange, :string
    change_column_null :securities, :identifier, true
    remove_index :securities, name: :index_securities_on_ticker
    add_index :securities, :ticker, unique: true, where: "exchange IS NULL", name: "index_securities_on_ticker_without_exchange"
    add_index :securities, [ :ticker, :exchange ], unique: true, where: "exchange IS NOT NULL", name: "index_securities_on_ticker_and_exchange"
  end

  def down
    remove_index :securities, name: :index_securities_on_ticker_without_exchange
    remove_index :securities, name: "index_securities_on_ticker_and_exchange"
    add_index :securities, :ticker, unique: true
    change_column_null :securities, :identifier, false
    remove_column :securities, :exchange
    remove_column :securities, :note
  end
end
