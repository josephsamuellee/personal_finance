require "test_helper"

class AccountArchiveTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @cash = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    @brokerage = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    @security = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD")
    AccountObservation.revise_current!({ account: @cash }, observed_on: Date.new(2026, 1, 1), updated_by: @user, amount: 100)
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.new(2026, 1, 1), updated_by: @user, amount: 50)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.new(2026, 1, 1), updated_by: @user, quantity: 2, cost_basis: 100)
    MarketPrice.upsert_effective!(security: @security, amount: 100, market_on: Date.new(2026, 1, 1), currency: "USD", source: "manual")
  end

  test "archiving hides the account from today's totals and keeps earlier as-of value" do
    travel_to Time.zone.local(2026, 10, 23, 12) do
      @brokerage.archive!
      today = Reporting::Snapshot.new(on: Date.current)
      earlier = Reporting::Snapshot.new(on: Date.new(2026, 1, 1))

      assert_nil today.components.find { |component| component.label.include?("Fidelity") || component.label.include?("VOO") }
      assert earlier.components.any? { |component| component.label.include?("VOO") }
      assert_equal 350, earlier.net_worth
      assert_equal 100, today.net_worth
    end
  end

  test "restore brings the account back without duplicating observations or prices" do
    observations = PositionObservation.where(account: @brokerage).count
    prices = MarketPrice.where(security: @security).count
    @brokerage.archive!
    @brokerage.unarchive!

    assert @brokerage.visible_on?(Date.current)
    assert_equal observations, PositionObservation.where(account: @brokerage).count
    assert_equal prices, MarketPrice.where(security: @security).count
  end

  test "archiving does not convert brokerage cash observations" do
    cash = AccountObservation.current_on({ account: @brokerage }, Date.new(2026, 1, 1))
    @brokerage.archive!

    assert_equal BigDecimal("50"), cash.reload.amount
    assert_equal Date.new(2026, 1, 1), cash.observed_on
  end
end
