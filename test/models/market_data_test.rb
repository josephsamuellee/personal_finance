require "test_helper"

class MarketDataTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @other = Account.create!(name: "IRA", account_type: "brokerage", currency: "USD")
    @security = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    @position = PositionObservation.revise_current!({ account: @account, security: @security }, observed_on: Date.new(2026, 3, 1), updated_by: @user, quantity: 50, cost_basis: 1)
    PositionObservation.revise_current!({ account: @other, security: @security }, observed_on: Date.new(2026, 3, 1), updated_by: @user, quantity: 5, cost_basis: 1)
    @cached = MarketPrice.create!(security: @security, amount: 20, currency: "USD", market_on: Date.new(2026, 3, 1), retrieved_at: Time.current, source: "manual", entered_by: @user)
  end

  test "one refresh asks once per security and a failure keeps the cache without verifying quantity" do
    spy = SpyAdapter.new
    result = MarketData::Refresh.new(adapter: spy).call
    assert_equal 1, spy.calls
    assert_equal [ @security ], result.updated
    assert_empty result.failed

    assert_no_changes -> { @position.reload.attributes.slice("quantity", "updated_at") } do
      result = MarketData::Refresh.new(adapter: BoomAdapter.new).call
      assert result.failure?
      assert_empty result.updated
      assert_equal [ @security ], result.failed
    end
    assert MarketPrice.exists?(@cached.id)
    assert_equal BigDecimal("20"), @cached.reload.amount
    state, = PositionObservation.state_on({ account: @account, security: @security }, Date.current)
    assert_equal :carried_forward, state
  end

  test "a partial refresh records the securities that failed and the ones that updated" do
    other = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: other }, observed_on: Date.new(2026, 3, 1), updated_by: @user, quantity: 2, cost_basis: 1)
    result = MarketData::Refresh.new(adapter: MixedAdapter.new).call

    assert_equal [ @security ], result.updated
    assert_equal [ other ], result.failed
    assert result.partial?
    assert MarketPrice.exists?(@cached.id)
  end

  test "an account-scoped refresh selects that account's open holdings once" do
    schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    aapl = Security.create!(ticker: "AAPL", identifier: "AAPL", currency: "USD")
    msft = Security.create!(ticker: "MSFT", identifier: "MSFT", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: aapl }, observed_on: Date.current, updated_by: @user, quantity: 3, cost_basis: 1)
    PositionObservation.revise_current!({ account: schwab, security: @security }, observed_on: Date.current, updated_by: @user, quantity: 4, cost_basis: 1)
    PositionObservation.revise_current!({ account: schwab, security: msft }, observed_on: Date.current, updated_by: @user, quantity: 1, cost_basis: 1)
    PositionObservation.revise_current!({ account: @account, security: msft }, observed_on: Date.current, updated_by: @user, quantity: 0, cost_basis: 1)
    spy = SpyAdapter.new
    result = MarketData::Refresh.new(adapter: spy, account: @account, on: Date.current).call

    assert_equal 2, spy.tickers.uniq.size
    assert_includes spy.tickers, "VOO"
    assert_includes spy.tickers, "AAPL"
    assert_not_includes spy.tickers, "MSFT"
    assert_equal result.updated.map(&:ticker).sort, %w[AAPL VOO]
  end

  test "a manual price on the reporting date is not overwritten" do
    MarketPrice.upsert_effective!(security: @security, amount: 99, market_on: Date.current, currency: "USD", source: "manual", entered_by: @user)
    result = MarketData::Refresh.new(adapter: SpyAdapter.new, account: @account, on: Date.current).call

    assert_includes result.kept_manual, @security
    assert_equal BigDecimal("99"), MarketPrice.effective_on(@security, Date.current).amount
  end

  test "a repeated refresh updates the existing price instead of accumulating rows" do
    MarketData::Refresh.new(adapter: SpyAdapter.new).call
    assert_equal 1, MarketPrice.where(security: @security, market_on: Date.new(2026, 10, 20)).count

    MarketData::Refresh.new(adapter: SpyAdapter.new).call

    assert_equal 1, MarketPrice.where(security: @security, market_on: Date.new(2026, 10, 20)).count
    assert_equal BigDecimal("11"), MarketPrice.where(security: @security, market_on: Date.new(2026, 10, 20)).pick(:amount)
  end

  class SpyAdapter < MarketData::Adapter
    NAME = "Spy"
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def quote(security)
      @calls += 1
      @tickers ||= []
      @tickers << security.ticker
      { amount: BigDecimal("11"), market_on: Date.new(2026, 10, 20), currency: "USD" }
    end

    def tickers
      @tickers || []
    end
  end

  class BoomAdapter < MarketData::Adapter
    NAME = "Boom"

    def quote(_security)
      raise MarketData::ProviderError, "unavailable"
    end
  end

  class MixedAdapter < MarketData::Adapter
    NAME = "Mixed"

    def quote(security)
      raise MarketData::ProviderError, "unavailable" if security.ticker == "QQQ"

      { amount: BigDecimal("3"), market_on: Date.new(2026, 10, 2), currency: "USD" }
    end
  end
end
