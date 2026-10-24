require "test_helper"
require Rails.root.join("db/migrate/20261023210100_make_market_prices_unique_per_date.rb")

class MarketPriceMigrationTest < ActiveSupport::TestCase
  INDEX_NAME = :index_market_prices_on_security_date_currency_convention

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.remove_index :market_prices, name: INDEX_NAME
  end

  teardown do
    unless @connection.index_exists?(:market_prices, nil, name: INDEX_NAME)
      @connection.add_index :market_prices, [ :security_id, :market_on, :currency, :adjustment_convention ],
                            unique: true, name: INDEX_NAME
    end
  end

  test "the dedupe keeps the latest retrieval per security, date, currency, and convention" do
    security = Security.create!(ticker: "VOO", currency: "USD")
    market_on = Date.current
    MarketPrice.create!(security:, amount: 10, currency: "USD", market_on:, retrieved_at: 2.days.ago, source: "manual")
    keeper = MarketPrice.create!(security:, amount: 11, currency: "USD", market_on:, retrieved_at: 1.day.ago, source: "manual")
    MarketPrice.create!(security:, amount: 12, currency: "EUR", market_on:, retrieved_at: 1.day.ago, source: "manual")

    MakeMarketPricesUniquePerDate.new.dedupe!(@connection)

    assert_equal [ keeper.id, MarketPrice.where(currency: "EUR").pick(:id) ].sort, MarketPrice.order(:id).pluck(:id)
    assert_equal 2, MarketPrice.count
  end

  test "retrieved_at ties break deterministically by id" do
    security = Security.create!(ticker: "QQQ", currency: "USD")
    market_on = Date.current
    at = Time.current
    MarketPrice.create!(security:, amount: 10, currency: "USD", market_on:, retrieved_at: at, source: "manual")
    keeper = MarketPrice.create!(security:, amount: 11, currency: "USD", market_on:, retrieved_at: at, source: "manual")

    MakeMarketPricesUniquePerDate.new.dedupe!(@connection)

    assert_equal keeper.id, MarketPrice.pick(:id)
  end

  test "the migration enforces one effective price per security, date, currency, and convention" do
    security = Security.create!(ticker: "XYZ", currency: "USD")
    MarketPrice.create!(security:, amount: 10, currency: "USD", market_on: Date.current, retrieved_at: Time.current, source: "manual")

    @connection.add_index :market_prices, [ :security_id, :market_on, :currency, :adjustment_convention ],
                          unique: true, name: INDEX_NAME

    assert_raises ActiveRecord::RecordNotUnique do
      MarketPrice.create!(security:, amount: 11, currency: "USD", market_on: Date.current, retrieved_at: Time.current, source: "manual")
    end
  end
end
