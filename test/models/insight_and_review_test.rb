require "test_helper"

class InsightAndReviewTest < ActiveSupport::TestCase
  test "insights name month-to-date spending and carried quantities without calling them verified" do
    user = create_user
    category = ExpenseCategory.create!(name: "Travel")
    account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    security = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    [ Date.new(2026, 7, 3), Date.new(2026, 8, 3), Date.new(2026, 9, 3) ].each do |date|
      Expense.create!(kind: "spending", amount: 10, spent_on: date, expense_category: category, created_by: user, updated_by: user)
    end
    Expense.create!(kind: "spending", amount: 40, spent_on: Date.new(2026, 10, 4), expense_category: category, created_by: user, updated_by: user)
    PositionObservation.revise_current!({ account:, security: }, observed_on: Date.new(2021, 3, 15), updated_by: user, quantity: 50, cost_basis: 10)
    RecurringItem.create!(name: "Insurance", direction: "obligation", amount: 80, frequency: "monthly", starts_on: Date.new(2026, 10, 28), treatment: "additional")
    insights = Reporting::Insights.build(on: Date.new(2026, 10, 21))

    spending = insights.find { |insight| insight.text.include?("tracked spending") }
    carried = insights.find { |insight| insight.text.include?("VOO") }
    upcoming = insights.find { |insight| insight.text.include?("Insurance") }

    assert_includes spending.text, "Month-to-date"
    assert_equal "estimate", spending.kind
    assert_includes carried.text, "2021-03-15"
    assert_not_includes carried.text.downcase, "verified"
    assert_includes upcoming.text, "2026-10-28"
    assert insights.none?(&:required)
    assert_equal 0, FinancialReview.count
  end

  test "a saved review freezes inputs and browsing does not create one" do
    user = create_user
    account = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    observation = AccountObservation.revise_current!({ account: }, observed_on: Date.new(2026, 10, 1), updated_by: user, amount: 25)
    review = FinancialReview.create!(review_on: Date.new(2026, 10, 1), commentary: "Looked fine", created_by: user)
    frozen = review.inputs
    observation.revision_user = user
    observation.update!(amount: 80, updated_by: user)

    assert_equal Reporting::CALCULATION_VERSION, review.calculation_version
    assert_equal frozen, review.reload.inputs
    assert_equal 1, FinancialReview.count
  end

  test "editing a decision keeps the decision date and the previous rationale" do
    user = create_user
    decision = FinancialDecision.create!(
      decided_on: Date.new(2024, 5, 1), description: "Refinance", rationale: "Rate fell",
      alternatives: "Wait", expected_effect: "Lower payment", created_by: user, updated_by: user
    )
    decision.revision_user = user
    decision.update!(rationale: "Rate fell further", updated_by: user)

    assert_equal Date.new(2024, 5, 1), decision.reload.decided_on
    assert_equal "Rate fell", decision.record_revisions.last.previous_values["rationale"]
  end

  test "portfolio value change is labeled and incomplete cash flows withhold a precise figure" do
    user = create_user
    account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    security = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    PositionObservation.revise_current!({ account:, security: }, observed_on: Date.new(2025, 1, 1), updated_by: user, quantity: 10, cost_basis: 100)
    MarketPrice.create!(security:, amount: 40, currency: "USD", market_on: Date.new(2025, 1, 1), retrieved_at: Time.current, source: "manual")
    MarketPrice.create!(security:, amount: 50, currency: "USD", market_on: Date.new(2026, 1, 1), retrieved_at: Time.current, source: "manual")
    withheld = Reporting::Benchmark.new(from: Date.new(2025, 1, 1), to: Date.new(2026, 1, 1), cash_flows_recorded: false)
    recorded = Reporting::Benchmark.new(from: Date.new(2025, 1, 1), to: Date.new(2026, 1, 1), cash_flows_recorded: true)

    assert_equal "Change in portfolio value", withheld.value_change[:label]
    assert_equal 100, withheld.value_change[:amount]
    assert_not withheld.performance[:available]
    assert_includes withheld.performance[:label], "not available"
    assert recorded.performance[:available]
    assert_equal "Adjusted for the recorded cash flows", recorded.performance[:label]
  end
end
