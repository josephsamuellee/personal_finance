require "test_helper"

class ExpenseTrackingTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @category = ExpenseCategory.create!(name: "Groceries")
    @checking = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    @savings = Account.create!(name: "Savings", account_type: "savings", currency: "USD")
  end

  test "tracked spending subtracts refunds and excludes transfers" do
    Expense.create!(kind: "spending", amount: 80, spent_on: Date.new(2026, 10, 2), expense_category: @category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "refund", amount: 30, spent_on: Date.new(2026, 10, 3), expense_category: @category, refund_of: Expense.first, created_by: @user, updated_by: @user)
    Expense.create!(kind: "refund", amount: 5, spent_on: Date.new(2026, 10, 4), expense_category: @category, created_by: @user, updated_by: @user)
    Expense.create!(kind: "transfer", amount: 1000, spent_on: Date.new(2026, 10, 5), source_account: @checking, destination_account: @savings, created_by: @user, updated_by: @user)

    assert_equal BigDecimal("45"), Reporting::Spending.total(Date.new(2026, 10, 1)..Date.new(2026, 10, 31))
  end

  test "a validation failure keeps the entered merchant" do
    expense = Expense.new(kind: "spending", amount: nil, spent_on: Date.current, merchant: "Market", expense_category: @category)
    assert_not expense.valid?
    assert_equal "Market", expense.merchant
  end
end
