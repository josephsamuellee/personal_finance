require "test_helper"

class ReportingRequestTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
  end

  test "home shows the dashboard summaries" do
    get root_path

    assert_response :success
    %w[Estimated\ net\ worth Liquid\ assets Tracked\ spending Three-month Estimated\ monthly\ surplus Asset\ allocation Net\ worth\ history Contextual\ insights].each do |heading|
      assert_includes response.body, heading
    end
    assert_no_match(/accuracy score/i, response.body)
  end

  test "home dashboard orders the cards, amounts, and charts" do
    category = ExpenseCategory.create!(name: "Food")
    account = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: }, observed_on: Date.current, updated_by: @user, amount: 40)
    Expense.create!(kind: "spending", amount: 8, spent_on: Date.current, expense_category: category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "spending", amount: 3, spent_on: Date.current.prev_month, expense_category: category, created_by: @user, updated_by: @user)

    get root_path

    ids = %w[net-worth liquid-assets tracked-spending spending-chart net-worth-history three-month-average estimated-surplus asset-allocation insights home-links]
    indexes = ids.map { |id| response.body.index(%(id="#{id}")) }
    assert_equal indexes.compact, indexes
    assert_equal ids.size, indexes.compact.size
    assert_includes response.body, "$8.00"
    assert_includes response.body, "$3.00"
    assert_select "#spending-chart [data-chart-mode-value=spending]"
    assert_select "#net-worth-history [data-chart-mode-value=net-worth]"
    assert_select "a.ui-button-secondary", text: "Compare periods"
    assert_select "a.ui-link", text: "Cash"
  end

  test "drill-down opens expenses, assets, and holding history" do
    account = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: }, observed_on: Date.new(2026, 10, 2), updated_by: @user, amount: 10)
    category = ExpenseCategory.create!(name: "Food")
    Expense.create!(kind: "spending", amount: 8, spent_on: Date.new(2026, 10, 3), expense_category: category, created_by: @user, updated_by: @user)
    brokerage = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    security = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    PositionObservation.revise_current!({ account: brokerage, security: }, observed_on: Date.new(2026, 10, 2), updated_by: @user, quantity: 1, cost_basis: 1)

    get expenses_path(month: "2026-10")
    assert_includes response.body, "Food"
    get assets_path(group: "cash")
    assert_includes response.body, "Checking"
    get holding_path(brokerage, security)
    assert_includes response.body, "VOO history"
  end

  test "comparison identifies missing and estimated values" do
    account = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    Account.create!(name: "House", account_type: "property", currency: "USD")
    AccountObservation.revise_current!({ account: }, observed_on: Date.new(2025, 10, 1), updated_by: @user, amount: 10)
    get compare_path(on: "2026-10-21", against: "prior_year")

    assert_includes response.body, "Estimated"
    assert_includes response.body, "Missing"
  end

  test "a saved review opens its frozen financial context" do
    account = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: }, observed_on: Date.new(2026, 10, 1), updated_by: @user, amount: 25)
    review = FinancialReview.create!(review_on: Date.new(2026, 10, 1), commentary: "Looked fine", created_by: @user)

    get review_path(review)

    assert_includes response.body, "Saved financial context"
    assert_includes response.body, "household-finance-1"
    assert_includes response.body, "Looked fine"
    assert_includes response.body, "25"
  end
end
