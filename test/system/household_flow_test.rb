require "application_system_test_case"

class HouseholdFlowTest < ApplicationSystemTestCase
  test "authentication, shared editing, quick expense, carry forward, and price refresh" do
    visit new_user_path
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"

    click_on "Add user"
    fill_in "Email", with: "bea@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"
    click_on "Sign out"

    visit new_session_path
    fill_in "Email", with: "bea@example.com"
    fill_in "Password", with: "password-password"
    click_on "Sign in"

    click_on "Quick Expense"
    fill_in "Amount", with: "18.25"
    fill_in "Category", with: "Groceries"
    click_on "Save"
    assert_text "Expense saved. You can enter another."
    expense = Expense.last
    visit expense_path(expense)
    click_on "Edit"
    fill_in "Merchant", with: "Corner store"
    click_on "Save"
    assert_text "Corner store"

    brokerage = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    other = Account.create!(name: "IRA", account_type: "brokerage", currency: "USD")
    voo = Security.create!(ticker: "VOO", identifier: "VOO", currency: "USD")
    qqq = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    user = User.find_by!(email_address: "bea@example.com")
    PositionObservation.revise_current!({ account: brokerage, security: voo }, observed_on: Date.new(2026, 3, 15), updated_by: user, quantity: 50, cost_basis: 100)
    PositionObservation.revise_current!({ account: other, security: qqq }, observed_on: Date.new(2026, 3, 15), updated_by: user, quantity: 3, cost_basis: 20)
    visit assets_path(on: "2026-10-21")
    assert_text "Carried forward from 2026-03-15"
    click_on "VOO"
    fill_in "editor-quantity", with: "50"
    fill_in "editor-basis", with: "100"
    click_on "New observation"
    assert_text "Verified"
    assert_text "Carried forward from 2026-03-15"

    MarketPrice.create!(security: voo, amount: 20, currency: "USD", market_on: Date.new(2026, 3, 1), retrieved_at: Time.current, source: "manual", entered_by: user)
    click_on "Refresh Prices"
    assert_text "Price refresh failed"
    assert_equal 50, PositionObservation.current_on({ account: brokerage, security: voo }, Date.new(2026, 10, 21)).quantity
    state, = PositionObservation.state_on({ account: other, security: qqq }, Date.new(2026, 10, 21))
    assert_equal :carried_forward, state
  end
end
