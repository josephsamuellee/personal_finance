require "application_system_test_case"

class BrokerageActionsTest < ApplicationSystemTestCase
  test "Assets and account details show the same 2 by 3 action grid" do
    visit new_user_path
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"

    account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    expected = [ "Add Holding", "Update Holdings via CSV", "Record Cash", "Update prices", "Remove Account" ]

    visit assets_path
    assert_selector "[data-primary-action]", text: "Refresh Prices"
    within("#account-card-#{account.id} [data-section='brokerage-actions']") do
      assert_equal expected, all("a, button").map(&:text)
      assert_selector "[data-empty-cell]"
    end

    visit account_path(account)
    within("[data-section='brokerage-actions']") do
      assert_equal expected, all("a, button").map(&:text)
      assert_selector "#update-prices"
      assert_selector "[data-empty-cell]"
    end
    assert_no_selector "[data-primary-action]", text: "Refresh Prices"
    click_on "Update Holdings via CSV"
    assert_selector "h1", text: /Import holdings/
  end
end
