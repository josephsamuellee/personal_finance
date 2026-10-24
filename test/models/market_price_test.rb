require "test_helper"

class MarketPriceTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @security = Security.create!(ticker: "VOO", currency: "USD")
  end

  test "effective_on returns only an exact-date price" do
    MarketPrice.upsert_effective!(security: @security, amount: 20, market_on: Date.new(2026, 3, 1),
                                  currency: "USD", source: "manual", entered_by: @user)

    assert_equal 20, MarketPrice.effective_on(@security, Date.new(2026, 3, 1)).amount
    assert_nil MarketPrice.effective_on(@security, Date.new(2026, 3, 2))
    assert_equal 20, MarketPrice.usable_on(@security, Date.new(2026, 3, 2)).amount
  end

  test "a same-day manual update replaces the effective price without a duplicate" do
    market_on = Date.new(2026, 10, 23)
    MarketPrice.upsert_effective!(security: @security, amount: 20, market_on:, currency: "USD",
                                  source: "manual", entered_by: @user, retrieved_at: 2.hours.ago)
    keeper = MarketPrice.upsert_effective!(security: @security, amount: 21, market_on:, currency: "USD",
                                           source: "manual", entered_by: @user)

    assert_equal 1, MarketPrice.where(security: @security, market_on:).count
    assert_equal 21, keeper.reload.amount
    assert_equal 21, MarketPrice.effective_on(@security, market_on).amount
  end

  test "a manual price affects every account holding valued on that date" do
    fidelity = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    PositionObservation.revise_current!({ account: fidelity, security: @security }, observed_on: Date.new(2026, 3, 1), updated_by: @user, quantity: 50, cost_basis: 1)
    PositionObservation.revise_current!({ account: schwab, security: @security }, observed_on: Date.new(2026, 3, 1), updated_by: @user, quantity: 5, cost_basis: 1)
    MarketPrice.upsert_effective!(security: @security, amount: 20, market_on: Date.new(2026, 3, 1), currency: "USD", source: "manual")
    snapshot = Reporting::Snapshot.new(on: Date.new(2026, 3, 1))

    snapshot = Reporting::Snapshot.new(on: Date.new(2026, 3, 1))

    values = snapshot.components.select { |component| component.record_type == "PositionObservation" }.map(&:amount)
    assert_equal [ BigDecimal("100"), BigDecimal("1000") ], values.sort.map(&:to_d)

    MarketPrice.upsert_effective!(security: @security, amount: 22, market_on: Date.new(2026, 3, 1), currency: "USD", source: "manual")
    fresh = Reporting::Snapshot.new(on: Date.new(2026, 3, 1))

    assert_equal [ BigDecimal("110"), BigDecimal("1100") ], fresh.components.select { |component| component.record_type == "PositionObservation" }.map(&:amount).sort.map(&:to_d)
  end
end
