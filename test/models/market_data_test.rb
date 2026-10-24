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

  class SpyAdapter < MarketData::Adapter
    NAME = "Spy"
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def quote(_security)
      @calls += 1
      { amount: BigDecimal("11"), market_on: Date.new(2026, 10, 20), currency: "USD" }
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
