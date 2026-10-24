require "application_system_test_case"

class BrokerageActionsTest < ApplicationSystemTestCase
  test "Assets and account details show a 2 by 2 grid and an archive footer" do
    visit new_user_path
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"

    account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    grid = [ "Add Holding", "Update Holdings via CSV", "Record Cash", "Update prices" ]

    visit assets_path
    assert_selector "[data-primary-action]", text: "Refresh Prices"
    within("#account-card-#{account.id}") do
      assert_equal grid, all("[aria-label='Brokerage actions'] a, [aria-label='Brokerage actions'] button").map(&:text)
      assert_selector "[data-section='brokerage-archive']", text: "Remove Account"
      assert_no_selector "[data-empty-cell]"
    end

    visit account_path(account)
    assert_equal grid, all("[aria-label='Brokerage actions'] a, [aria-label='Brokerage actions'] button").map(&:text)
    assert_selector "[data-section='brokerage-archive']", text: "Remove Account"
    assert_no_selector "[data-primary-action]", text: "Refresh Prices"
    click_on "Update Holdings via CSV"
    assert_selector "h1", text: /Import holdings/
  end
end
