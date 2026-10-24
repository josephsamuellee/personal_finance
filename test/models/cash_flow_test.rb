require "test_helper"

class CashFlowTest < ActiveSupport::TestCase
  test "included recurring items are not added on top of tracked spending" do
    on = Date.new(2026, 10, 21)
    RecurringItem.create!(name: "Pay", direction: "income", amount: 1000, frequency: "monthly", starts_on: Date.new(2026, 1, 1), treatment: "additional")
    RecurringItem.create!(name: "Streaming", direction: "obligation", amount: 40, frequency: "monthly", starts_on: Date.new(2026, 1, 1), treatment: "included_in_tracked_spending")
    RecurringItem.create!(name: "Insurance", direction: "obligation", amount: 10, frequency: "monthly", starts_on: Date.new(2026, 1, 1), treatment: "additional")
    estimate = Reporting::Surplus.estimate(on)

    assert_equal BigDecimal("990"), estimate[:amount]
    assert_equal "Estimate", estimate[:label]
  end

  test "overlapping savings targets are rejected and a later period keeps the earlier target" do
    first = SavingsGoal.create!(amount: 500, starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 3, 31), reason: "Winter")
    overlap = SavingsGoal.new(amount: 100, starts_on: Date.new(2026, 2, 1), ends_on: Date.new(2026, 2, 28), reason: "Overlap")
    later = SavingsGoal.create!(amount: 200, starts_on: Date.new(2026, 4, 1), ends_on: Date.new(2026, 6, 30), reason: "Spring")

    assert_not overlap.valid?
    assert SavingsGoal.exists?(first.id)
    assert_equal first, SavingsGoal.applicable_on(Date.new(2026, 2, 1))
    assert_equal later, SavingsGoal.applicable_on(Date.new(2026, 5, 1))
  end

  test "the surplus alert is informational" do
    travel_to Date.new(2026, 10, 21) do
      category = ExpenseCategory.create!(name: "Rent")
      user = create_user
      [ Date.new(2026, 5, 2), Date.new(2026, 6, 2), Date.new(2026, 7, 2), Date.new(2026, 8, 2) ].each do |date|
        Expense.create!(kind: "spending", amount: 900, spent_on: date, expense_category: category, created_by: user, updated_by: user)
      end
      SavingsGoal.create!(amount: 100, starts_on: Date.new(2026, 1, 1), reason: "Target")
      message = Reporting::Surplus.below_target_message(Date.new(2026, 10, 21))

      assert_includes message, "informational"
      assert_equal 0, FinancialReview.count
    end
  end

  test "spending baseline uses the previous three completed months" do
    category = ExpenseCategory.create!(name: "Food")
    user = create_user
    Expense.create!(kind: "spending", amount: 100, spent_on: Date.new(2026, 7, 2), expense_category: category, created_by: user, updated_by: user)
    Expense.create!(kind: "spending", amount: 200, spent_on: Date.new(2026, 8, 2), expense_category: category, created_by: user, updated_by: user)
    Expense.create!(kind: "spending", amount: 300, spent_on: Date.new(2026, 9, 2), expense_category: category, created_by: user, updated_by: user)
    Expense.create!(kind: "spending", amount: 999, spent_on: Date.new(2026, 10, 2), expense_category: category, created_by: user, updated_by: user)
    baseline = Reporting::Spending.baseline(Date.new(2026, 10, 21))

    assert_equal [ Date.new(2026, 9, 1), Date.new(2026, 8, 1), Date.new(2026, 7, 1) ], baseline[:months]
    assert_equal BigDecimal("200"), baseline[:average]
  end
end
