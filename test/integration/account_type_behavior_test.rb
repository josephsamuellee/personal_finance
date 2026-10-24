require "test_helper"

class AccountTypeBehaviorTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
    @brokerage = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @voo = Security.create!(ticker: "VOO", currency: "USD")
    PositionObservation.revise_current!({ account: @brokerage, security: @voo },
                                        observed_on: Date.new(2026, 3, 15), updated_by: @user,
                                        quantity: 50, cost_basis: 18_000)
    MarketPrice.upsert_effective!(security: @voo, amount: 400, market_on: Date.new(2026, 3, 15),
                                  currency: "USD", source: "manual", entered_by: @user)
  end

  test "a checking account offers Update balance as the primary action with the latest balance and today prefilled" do
    checking = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: checking }, observed_on: Date.new(2026, 3, 15),
                                       updated_by: @user, amount: 1_250)

    get assets_path(on: "2026-03-15", balance: checking.id)

    assert_select "#update-balance-#{checking.id}.ui-button-quiet"
    assert_select "input[name=amount][value=?]", "1250.0"
    assert_select "input[name=observed_on][value=?]", "2026-03-15"
    assert_select "button", text: "Save balance"
    assert_select "[data-section=observation-status]", text: /Verified/
    assert_select "[data-controller=reveal-panel][data-reveal-panel-focus-value=balance-editor-title]"
  end

  test "a brokerage with no cash records shows no cash row and counts cash as zero" do
    get assets_path(on: "2026-03-15")

    assert_select "#account-card-#{@brokerage.id}", text: "Cash", count: 0
    assert_select "#account-card-#{@brokerage.id}", text: /\$20,000\.00/
    assert_select "#account-card-#{@brokerage.id}", text: "Incomplete", count: 0
  end

  test "recorded brokerage cash shows a cash row and is counted exactly once" do
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.new(2026, 3, 15),
                                       updated_by: @user, amount: 500)

    get assets_path(on: "2026-03-15")

    assert_select "#account-card-#{@brokerage.id} span", text: "Cash"
    assert_select "#account-card-#{@brokerage.id}", text: /\$500\.00/
    assert_select "#account-card-#{@brokerage.id}", text: /\$20,500\.00/
  end

  test "zero brokerage cash hides the cash row but keeps its history" do
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.new(2026, 3, 1),
                                       updated_by: @user, amount: 500)
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.new(2026, 3, 15),
                                       updated_by: @user, amount: 0)

    get assets_path(on: "2026-03-15")

    assert_select "#account-card-#{@brokerage.id} span", text: "Cash", count: 0
    assert_select "#account-card-#{@brokerage.id}", text: /\$20,000\.00/
    assert_equal 2, AccountObservation.where(account: @brokerage).count
  end

  test "recording brokerage cash uses the Record cash action and the Save cash control" do
    get assets_path(on: "2026-03-15", balance: @brokerage.id)

    assert_select "#record-cash-#{@brokerage.id}.ui-button-quiet"
    assert_select "button", text: "Save cash"

    post holding_balances_path, params: {
      account_id: @brokerage.id, observed_on: "2026-03-15", amount: "500", gesture: "verify", historical_ack: "1"
    }
    assert_redirected_to assets_path(on: "2026-03-15")
    assert_equal 500, AccountObservation.current_on({ account_id: @brokerage.id }, Date.new(2026, 3, 15)).amount
  end

  test "a brokerage shows no independently editable aggregate balance entry" do
    get assets_path(on: "2026-03-15")

    assert_select "#account-card-#{@brokerage.id} a", text: "Update balance", count: 0
  end

  test "a brokerage Assets card offers CSV, Update prices, and Remove Account" do
    get assets_path(on: "2026-03-15")

    assert_select "#record-cash-#{@brokerage.id}"
    assert_select "#update-holdings-csv-#{@brokerage.id}[href=?]", new_account_holdings_import_path(@brokerage)
    assert_select "#update-prices-#{@brokerage.id}"
    assert_select "#remove-account-#{@brokerage.id}"
    assert_select "[data-primary-action]", text: "Refresh Prices"
  end

  test "Update prices from Assets is account-scoped and Remove Account archives" do
    schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    other = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    PositionObservation.revise_current!({ account: schwab, security: other }, observed_on: Date.current, updated_by: @user, quantity: 3, cost_basis: 1)
    MarketData::Refresh.adapter = AccountSpyAdapter.new
    post refresh_prices_account_path(@brokerage, on: Date.current.iso8601)
    follow_redirect!

    assert_equal [ "VOO" ], MarketData::Refresh.adapter.tickers
    assert_includes response.body, "Prices refreshed"

    patch account_path(@brokerage), params: { archive: "1" }
    assert @brokerage.reload.archived_at.present?
  ensure
    MarketData::Refresh.adapter = nil
  end

  class AccountSpyAdapter < MarketData::Adapter
    NAME = "AccountSpy"
    attr_reader :tickers

    def initialize
      @tickers = []
    end

    def quote(security)
      @tickers << security.ticker
      { amount: BigDecimal("11"), market_on: Date.current, currency: "USD" }
    end
  end
end
