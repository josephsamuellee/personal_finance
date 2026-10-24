require "test_helper"

class InterfaceTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
  end

  test "empty household pages explain what to do next" do
    get root_path
    assert_includes response.body, "No history yet"
    get expenses_path
    assert_includes response.body, "No expenses recorded yet"
    assert_select "[data-empty-state=empty]"
    get assets_path
    assert_includes response.body, "No holdings recorded yet"
    assert_includes response.body, "Add an account"
    assert_includes response.body, "Add an investment holding"
    assert_includes response.body, "Record a balance"
    assert_select "h2", text: "Balances", count: 0
    get reviews_path
    assert_includes response.body, "No reviews saved yet"
    get accounts_path
    assert_includes response.body, "No accounts yet"
    get new_expense_import_path
    assert_includes response.body, "No imports yet"
    get savings_goals_path
    assert_includes response.body, "No savings targets yet"
    get recurring_items_path
    assert_includes response.body, "No recurring items yet"
    get decisions_path
    assert_includes response.body, "No decisions recorded yet"
  end

  test "task links are buttons and record names stay text links" do
    account = Account.create!(name: "Cash", account_type: "checking", currency: "USD")
    security = Security.create!(ticker: "VOO", identifier: "Vanguard", currency: "USD")
    PositionObservation.revise_current!({ account:, security: }, observed_on: Date.current, updated_by: @user, quantity: 1, cost_basis: 1)

    get expenses_path
    assert_select "a.ui-button-secondary", text: "Import CSV"
    get accounts_path
    assert_select "a.ui-link", text: "Cash"
    assert_select "a.ui-button-secondary", text: "Cash", count: 0
    get assets_path
    assert_select "a.ui-button-secondary", text: "Manage accounts"
    assert_select "a.ui-link", text: "VOO"
    assert_select "a.ui-button-secondary", text: "VOO", count: 0
  end

  test "expense and review status pages use cards and keep record links" do
    category = ExpenseCategory.create!(name: "Food")
    expense = Expense.create!(kind: "spending", amount: 8, spent_on: Date.current, expense_category: category, created_by: @user, updated_by: @user)
    review = FinancialReview.create!(review_on: Date.current, commentary: "Fine", created_by: @user)
    decision = FinancialDecision.create!(description: "Kept the cash", decided_on: Date.current, rationale: "Buffer", alternatives: "Spend it", expected_effect: "Steady cash", created_by: @user)

    get expenses_path
    assert_select "#month-total"
    assert_select "#categories"
    assert_select "#expense-ledger"
    assert_select "#three-month-average"
    assert_select "#expense-import a.ui-button-secondary", text: "Import CSV"
    assert_select "#expense-ledger a.ui-link[href=?]", expense_path(expense)
    assert_select "#month-total a.ui-button", text: "Record an expense"

    before = FinancialReview.count
    get reviews_path
    assert_equal before, FinancialReview.count
    assert_includes response.body, "Opening this page does not save a review."
    assert_select "#saved-reviews a.ui-link", text: review.review_on.to_s
    assert_select "#decisions a.ui-link", text: decision.description
    assert_select "#review-links a.ui-button-secondary", text: "Compare periods"
  end

  test "a blank account name is identified beside the field" do
    assert_no_difference -> { Account.count } do
      post accounts_path, params: { account: { name: "", account_type: "checking", currency: "USD" } }
    end

    assert_response :unprocessable_entity
    assert_select "input[name=?][aria-invalid=true][aria-describedby=?]", "account[name]", "account_name_error"
    assert_select "#account_name_error", text: /can't be blank/
    assert_select "input[name=?][value=?]", "account[currency]", "USD"
  end

  test "a month with no matches is different from a household with no expenses" do
    Expense.create!(kind: "spending", amount: 4, spent_on: Date.new(2026, 1, 4), created_by: @user, updated_by: @user, expense_category: ExpenseCategory.create!(name: "Food"))
    get expenses_path(month: "2026-02")

    assert_includes response.body, "No expenses match this month"
    assert_not_includes response.body, "No expenses recorded yet"
    assert_select "[data-empty-state=filter]"
  end

  test "an assets filter with no matches is different from an empty household" do
    Account.create!(name: "House", account_type: "property", currency: "USD")
    get assets_path(group: "cash")

    assert_includes response.body, "No records match this view"
    assert_not_includes response.body, "No holdings recorded yet"
  end

  test "a failed load is not presented as an empty household" do
    with_failing_expense_load { get expenses_path }

    assert_includes response.body, "This section could not be loaded"
    assert_not_includes response.body, "No expenses recorded yet"
    assert_select "[data-empty-state=error]"
  end

  def with_failing_expense_load
      Expense.singleton_class.alias_method :kept_before_failure, :kept
      Expense.define_singleton_method(:kept) { raise ActiveRecord::StatementInvalid, "down" }
      yield
    ensure
      Expense.singleton_class.alias_method :kept, :kept_before_failure
      Expense.singleton_class.remove_method :kept_before_failure
    end

  test "price refresh reports success, a partial failure, and a total failure" do
    account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    voo = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    qqq = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    PositionObservation.revise_current!({ account:, security: voo }, observed_on: Date.current, updated_by: @user, quantity: 1, cost_basis: 1)
    PositionObservation.revise_current!({ account:, security: qqq }, observed_on: Date.current, updated_by: @user, quantity: 1, cost_basis: 1)
    cached = MarketPrice.create!(security: qqq, amount: 8, currency: "USD", market_on: Date.current - 5, retrieved_at: Time.current, source: "manual", entered_by: @user)

    get assets_path
    assert_includes response.body, "Refreshing prices"

    MarketData::Refresh.adapter = SuccessAdapter.new
    post refresh_market_prices_path
    follow_redirect!
    assert_includes response.body, "Prices refreshed. Latest price"
    assert_not_includes response.body, "failed"

    MarketData::Refresh.adapter = MixedAdapter.new
    post refresh_market_prices_path
    follow_redirect!
    assert_includes response.body, "Price refresh was partial"
    assert_includes response.body, "QQQ"
    assert_not_includes response.body, "Prices refreshed"
    assert MarketPrice.exists?(cached.id)

    MarketData::Refresh.adapter = BoomAdapter.new
    post refresh_market_prices_path
    follow_redirect!
    assert_includes response.body, "Price refresh failed"
    assert_not_includes response.body, "Prices refreshed"
    assert_equal BigDecimal("8"), cached.reload.amount
  ensure
    MarketData::Refresh.adapter = nil
  end

  class SuccessAdapter < MarketData::Adapter
    NAME = "Success"

    def quote(_security)
      { amount: BigDecimal("4"), market_on: Date.new(2026, 10, 20), currency: "USD" }
    end
  end

  class MixedAdapter < MarketData::Adapter
    NAME = "Mixed"

    def quote(security)
      raise MarketData::ProviderError, "unavailable" if security.ticker == "QQQ"

      { amount: BigDecimal("4"), market_on: Date.new(2026, 10, 20), currency: "USD" }
    end
  end

  class BoomAdapter < MarketData::Adapter
    NAME = "Boom"

    def quote(_security)
      raise MarketData::ProviderError, "unavailable"
    end
  end
end
