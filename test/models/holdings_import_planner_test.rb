require "test_helper"

class HoldingsImportPlannerTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    @other = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD", note: "Core")
    PositionObservation.revise_current!({ account: @other, security: @voo }, observed_on: Date.current, updated_by: @user, quantity: 5, cost_basis: 1000)
    PositionObservation.revise_current!({ account: @account, security: @voo }, observed_on: Date.current, updated_by: @user, quantity: 50, cost_basis: 18_000)
    MarketPrice.upsert_effective!(security: @voo, amount: 540, market_on: Date.current, currency: "USD", source: "manual")
    @aapl = Security.find_or_create_by_identity!(ticker: "AAPL", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: @aapl }, observed_on: Date.current, updated_by: @user, quantity: 2, cost_basis: 400)
  end

  test "a snapshot quantity of 55 replaces 50 rather than adding" do
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,55,18000,
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert_equal BigDecimal("55"), planned.quantity
    assert_includes planned.outcomes, "updated observation"
  end

  test "an existing ticker is reused and a blank note is preserved" do
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,55,18000,
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert_equal @voo.id, planned.security.id
    assert_equal "Core", planned.previous_note
    assert_not_includes planned.outcomes, "shared note change"
  end

  test "a nonblank note change is a shared note update" do
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,Updated,,#{Date.current},50,18000,
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert_includes planned.outcomes, "shared note change"
  end

  test "a missing exact-date price blocks the row" do
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      XYZ,,USD,,1,1,
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert_not planned.valid?
    assert_includes planned.errors.join, "price"
  end

  test "a conflicting price requires authorization and names the saved price" do
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,50,18000,510
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert planned.price_conflict?
    assert_includes planned.errors.join, "540"
  end

  test "an ambiguous ticker is blocked" do
    Security.create!(ticker: "VOO", exchange: "ARCX", currency: "USD")
    rows = parse(<<~CSV)
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,50,18000,
    CSV
    planned = HoldingsImport::Planner.new(account: @account, captured_on: Date.current, rows:).plan.first

    assert_includes planned.errors.join, "more than one"
  end

  def parse(csv)
    HoldingCsv.parse(csv, captured_on: Date.current).rows
  end
end
