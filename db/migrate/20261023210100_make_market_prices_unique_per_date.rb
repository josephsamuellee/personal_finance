class MakeMarketPricesUniquePerDate < ActiveRecord::Migration[7.2]
  def up
    add_column :market_prices, :adjustment_convention, :string, null: false, default: "raw"
    dedupe!(connection)
    add_index :market_prices, [ :security_id, :market_on, :currency, :adjustment_convention ],
              unique: true, name: :index_market_prices_on_security_date_currency_convention
  end

  def down
    remove_index :market_prices, name: :index_market_prices_on_security_date_currency_convention
    remove_column :market_prices, :adjustment_convention
  end

  # Keep one effective price per (security, market date, currency, adjustment
  # convention): the row with the latest retrieval time, breaking ties by id.
  def dedupe!(connection)
    connection.execute(<<~SQL.squish)
      DELETE FROM market_prices
      WHERE EXISTS (
        SELECT 1 FROM market_prices other
        WHERE other.security_id = market_prices.security_id
          AND other.market_on = market_prices.market_on
          AND other.currency = market_prices.currency
          AND other.adjustment_convention = market_prices.adjustment_convention
          AND (other.retrieved_at > market_prices.retrieved_at
               OR (other.retrieved_at = market_prices.retrieved_at AND other.id > market_prices.id))
      )
    SQL
  end
end
