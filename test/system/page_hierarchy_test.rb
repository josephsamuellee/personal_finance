require "application_system_test_case"

class PageHierarchyTest < ApplicationSystemTestCase
  test "home expenses assets and review show a purpose and one primary action" do
    visit new_user_path
    fill_in "Email", with: "ada@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"

    assert_selector "h1", text: "Home"
    assert_selector "[data-page-purpose]", text: "See the household's current finances."
    assert_selector "[data-primary-action]", text: "Record an expense"

    within("aside") { click_on "Expenses" }
    assert_selector "h1", text: "Expenses"
    assert_selector "[data-page-purpose]", text: "Review spending for the selected month."
    assert_selector "[data-primary-action]", text: "Record an expense"

    within("aside") { click_on "Assets" }
    assert_selector "h1", text: "Assets"
    assert_selector "[data-page-purpose]", text: "Update balances and holdings for the reporting date."
    assert_selector "[data-primary-action]", text: "Add an account"
    assert_text "No holdings recorded yet"

    within("aside") { click_on "Review" }
    assert_selector "h1", text: "Review"
    assert_selector "[data-page-purpose]", text: "Save an optional snapshot of this month."
    assert_selector "[data-primary-action]", text: "Save a review"
  end
end
