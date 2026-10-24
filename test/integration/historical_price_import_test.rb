require "test_helper"

class HistoricalPriceImportTest < ActionDispatch::IntegrationTest
  ROWS = {
    "2026-01-02" => "390.5",
    "2026-01-03" => "391.0",
    "2026-01-05" => "392.25"
  }.freeze

  setup do
    @user = create_user
    sign_in_as(@user)
    @security = Security.create!(ticker: "VOO", currency: "USD")
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: @security },
                                       observed_on: Date.new(2026, 1, 5), updated_by: @user, quantity: 2, cost_basis: 100)
    @adapter = CountingHistoryAdapter.new(ROWS)
    MarketData::Import.adapter = @adapter
  end

  teardown do
    MarketData::Import.adapter = nil
  end

  test "the import form is reachable and only imports on request" do
    get asset_maintenance_path(form: "import")

    assert_select "select[name=security_id]"
    assert_select "input[name=from]"
    assert_select "input[name=to]"
    assert_select "input[name=replace]", count: 1
    assert_equal 0, @adapter.calls

    assert_difference -> { MarketPrice.count }, 3 do
      post import_market_prices_path, params: { security_id: @security.id, from: "2026-01-01", to: "2026-01-31" }
    end
    assert_redirected_to asset_maintenance_path(form: "import")
    assert_equal 1, @adapter.calls
  end

  test "a failed import keeps cached prices and explains the failure" do
    MarketData::Import.adapter = BoomAdapter.new

    post import_market_prices_path, params: { security_id: @security.id, from: "2026-01-01", to: "2026-01-31" }
    follow_redirect!

    assert_includes response.body, "Import failed for VOO"
    assert_includes response.body, "Cached prices were kept"
  end

  test "non-trading dates get no records and reports reuse the cache without new requests" do
    post import_market_prices_path, params: { security_id: @security.id, from: "2026-01-01", to: "2026-01-31" }

    assert_nil MarketPrice.effective_on(@security, Date.new(2026, 1, 4))

    get assets_path(on: "2026-01-05")
    assert_includes response.body, "784.5"
    get root_path

    assert_equal 1, @adapter.calls
  end

  test "the explicit replace choice lets provider data replace a manual price" do
    MarketPrice.upsert_effective!(security: @security, amount: 1, market_on: Date.new(2026, 1, 5),
                                  currency: "USD", source: "manual", entered_by: @user)

    post import_market_prices_path, params: { security_id: @security.id, from: "2026-01-01", to: "2026-01-31", replace: "1" }

    price = MarketPrice.effective_on(@security, Date.new(2026, 1, 5))
    assert_equal BigDecimal("392.25"), price.amount
    assert_equal "Counting", price.source
  end

  class CountingHistoryAdapter < MarketData::Adapter
    NAME = "Counting"
    attr_reader :calls

    def initialize(rows)
      @rows = rows
      @calls = 0
    end

    def history(_security, from:, to:)
      @calls += 1
      @rows.filter_map do |date, amount|
        market_on = Date.parse(date)
        (from..to).cover?(market_on) ? { amount: BigDecimal(amount), market_on:, currency: "USD", adjustment_convention: "raw" } : nil
      end
    end
  end

  class BoomAdapter < MarketData::Adapter
    NAME = "Boom"

    def history(_security, from:, to:)
      raise MarketData::ProviderError, "unavailable"
    end
  end
end
