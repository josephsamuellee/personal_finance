require "test_helper"

class ReportingTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @cash = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    @brokerage = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @security = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
  end

  test "carried values stay in an estimated total and unknown prices are not zero" do
    AccountObservation.revise_current!({ account: @cash }, observed_on: Date.new(2026, 3, 1), updated_by: @user, amount: 1_000)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.new(2026, 10, 1), updated_by: @user, quantity: 2, cost_basis: 100)
    snapshot = Reporting::Snapshot.new(on: Date.new(2026, 10, 21))

    assert snapshot.estimated?
    assert snapshot.incomplete?
    assert_equal 1000, snapshot.net_worth
    assert_equal "Incomplete Estimated", snapshot.quality_label
    assert_not_equal 0, snapshot.components.find { |component| component.label.include?("VOO") }.amount
  end

  test "an unconverted balance makes the USD total incomplete" do
    euros = Account.create!(name: "Euro", account_type: "savings", currency: "EUR")
    AccountObservation.revise_current!({ account: euros }, observed_on: Date.current, updated_by: @user, amount: 50)
    snapshot = Reporting::Snapshot.new(on: Date.current)

    assert snapshot.incomplete?
    assert_equal 0, snapshot.net_worth
  end

  test "brokerage value is cash plus derived positions" do
    AccountObservation.revise_current!({ account: @cash }, observed_on: Date.current, updated_by: @user, amount: 0)
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.current, updated_by: @user, amount: 1_000)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.current, updated_by: @user, quantity: 2, cost_basis: 100)
    MarketPrice.create!(security: @security, amount: 100, currency: "USD", market_on: Date.current, retrieved_at: Time.current, source: "manual", entered_by: @user)
    snapshot = Reporting::Snapshot.new(on: Date.current)

    position = snapshot.components.find { |component| component.label.include?("VOO") }

    assert_not snapshot.incomplete?
    assert_equal 1200, snapshot.net_worth
    assert_equal 1000, snapshot.liquid_assets
    assert_equal 200, position.amount
    assert_equal 100, position.unrealized_gain
  end

  test "a brokerage without recorded cash is valued from its holdings and is not incomplete" do
    AccountObservation.revise_current!({ account: @cash }, observed_on: Date.current, updated_by: @user, amount: 0)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.current, updated_by: @user, quantity: 2, cost_basis: 100)
    MarketPrice.upsert_effective!(security: @security, amount: 100, market_on: Date.current, currency: "USD", source: "manual")
    snapshot = Reporting::Snapshot.new(on: Date.current)

    assert_not snapshot.incomplete?
    assert_equal 200, snapshot.net_worth
    assert_nil snapshot.components.find { |component| component.record_type == "AccountObservation" && component.label == "Brokerage" }
  end

  test "recorded zero brokerage cash contributes zero without double counting" do
    AccountObservation.revise_current!({ account: @brokerage }, observed_on: Date.current, updated_by: @user, amount: 0)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.current, updated_by: @user, quantity: 2, cost_basis: 100)
    MarketPrice.upsert_effective!(security: @security, amount: 100, market_on: Date.current, currency: "USD", source: "manual")
    snapshot = Reporting::Snapshot.new(on: Date.current)

    assert_equal 200, snapshot.net_worth
    assert_equal 1, snapshot.components.count { |component| component.label == "Brokerage" }
  end

  test "snapshot output distinguishes the requested date from the effective price date" do
    AccountObservation.revise_current!({ account: @cash }, observed_on: Date.current, updated_by: @user, amount: 0)
    PositionObservation.revise_current!({ account: @brokerage, security: @security },
                                        observed_on: Date.current - 1, updated_by: @user, quantity: 2, cost_basis: 100)
    MarketPrice.upsert_effective!(security: @security, amount: 100, market_on: Date.current - 2,
                                  currency: "USD", source: "manual")
    snapshot = Reporting::Snapshot.new(on: Date.current)

    position = snapshot.components.find { |component| component.label.include?("VOO") }
    assert_equal Date.current - 1, position.source_date
    assert_equal Date.current - 2, position.price_date

    payload = snapshot.to_h[:components].find { |component| component[:label].include?("VOO") }
    assert_equal (Date.current - 1).iso8601, payload[:source_date]
    assert_equal (Date.current - 2).iso8601, payload[:price_date]
  end

  test "daily spending bins exclude transfers, keep refunds negative, and restart each month" do
    category = ExpenseCategory.create!(name: "Food")
    savings = Account.create!(name: "Savings", account_type: "savings", currency: "USD")
    on = Date.new(2026, 10, 3)
    Expense.create!(kind: "spending", amount: 7, spent_on: Date.new(2026, 9, 30), expense_category: category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "spending", amount: 10, spent_on: Date.new(2026, 10, 1), expense_category: category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "refund", amount: 4, spent_on: Date.new(2026, 10, 3), expense_category: category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "transfer", amount: 100, spent_on: Date.new(2026, 10, 3), source_account: @cash, destination_account: savings, created_by: @user, updated_by: @user)
    chart = Reporting::Spending.daily_chart(on)
    september = chart.find { |point| point[:date] == "2026-09-30" }
    october_first = chart.find { |point| point[:date] == "2026-10-01" }
    october_second = chart.find { |point| point[:date] == "2026-10-02" }
    october_third = chart.find { |point| point[:date] == "2026-10-03" }

    assert_equal "0.0", october_second[:amount]
    assert_equal "-4.0", october_third[:amount]
    assert_equal "7.0", september[:cumulative]
    assert_equal "10.0", october_first[:cumulative]
    assert_equal "6.0", october_third[:cumulative]
    assert_equal (Date.new(2026, 8, 1)..on).count, chart.size
  end

  test "detailed series keep observation dates and monthly series use the latest observation" do
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.new(2021, 8, 10), updated_by: @user, quantity: 4, cost_basis: 1)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.new(2021, 8, 24), updated_by: @user, quantity: 8, cost_basis: 1)
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.new(2021, 9, 4), updated_by: @user, quantity: 9, cost_basis: 1)
    scope = PositionObservation.where(account: @brokerage, security: @security)
    detailed = Reporting::Series.detailed(scope)
    monthly = Reporting::Series.monthly_latest(scope)

    assert_equal [ "2021-08-10", "2021-08-24", "2021-09-04" ], detailed.map { |point| point[:date] }
    assert_equal "2021-08-24", monthly.find { |point| point[:month] == "2021-08" }[:date]
    assert_equal "8.0", monthly.find { |point| point[:month] == "2021-08" }[:amount]
  end

  test "missing price market value is unknown rather than zero" do
    PositionObservation.revise_current!({ account: @brokerage, security: @security }, observed_on: Date.current, updated_by: @user, quantity: 2, cost_basis: 10)
    component = Reporting::Snapshot.new(on: Date.current).components.find { |item| item.group == "Investments" }

    assert component.unknown
    assert_nil component.amount
  end

  test "valuation uses the latest price on or before the date" do
    MarketPrice.create!(security: @security, amount: 10, currency: "USD", market_on: Date.new(2026, 1, 1), retrieved_at: Time.current, source: "manual")
    MarketPrice.create!(security: @security, amount: 12, currency: "USD", market_on: Date.new(2026, 2, 1), retrieved_at: Time.current, source: "manual")
    MarketPrice.create!(security: @security, amount: 99, currency: "USD", market_on: Date.new(2026, 3, 1), retrieved_at: Time.current, source: "manual")

    assert_equal 12, MarketPrice.usable_on(@security, Date.new(2026, 2, 15)).amount
  end
end
