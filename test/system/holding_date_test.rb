require "application_system_test_case"

class HoldingDateTest < ApplicationSystemTestCase
  setup do
    visit new_user_path
    fill_in "Email", with: "joseph@example.com"
    fill_in "Password", with: "password-password"
    fill_in "Confirm password", with: "password-password"
    click_on "Save user"

    @user = User.find_by!(email_address: "joseph@example.com")
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @security = Security.create!(ticker: "VOO", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: @security },
                                        observed_on: Date.current, updated_by: @user, quantity: 50, cost_basis: 18_000)
  end

  test "a past observation date warns, blocks the save without acknowledgment, and clears when back to today" do
    visit assets_path(on: (Date.current - 7).iso8601, edit: "#{@account.id}-#{@security.id}")

    assert_selector "[data-section=historical-warning]"
    assert has_unchecked_field?("I intend to record this historical observation")

    fill_in "Quantity", with: "60"
    fill_in "Cost basis", with: "18000"
    click_on "New observation"

    assert_selector "[data-section=historical-warning]"
    assert_equal 1, PositionObservation.count

    check "I intend to record this historical observation"
    click_on "New observation"

    assert_text "Holding saved"
    assert_equal 2, PositionObservation.count

    visit assets_path(on: Date.current.iso8601, edit: "#{@account.id}-#{@security.id}")

    assert_no_selector "[data-section=historical-warning]"
  end

  test "reloading a new date preserves unsaved edits instead of silently discarding them" do
    visit assets_path(on: Date.current.iso8601, edit: "#{@account.id}-#{@security.id}")

    fill_in "Quantity", with: "77"
    fill_in "Observation date", with: (Date.current - 3).iso8601
    click_on "Update date"

    assert_field "Quantity", with: "77"
    assert_selector "[data-section=historical-warning]"
  end

  test "a past-dated balance save requires acknowledgment" do
    checking = Account.create!(name: "Checking", account_type: "checking", currency: "USD")

    visit assets_path(on: (Date.current - 5).iso8601, balance: checking.id)

    assert_selector "[data-section=historical-warning]"
    fill_in "Amount", with: "100"
    click_on "Save balance"
    assert_equal 0, AccountObservation.count

    check "I intend to record this historical observation"
    click_on "Save balance"

    assert_equal 1, AccountObservation.count
  end

  test "selecting a holding from the brokerage account details opens the editor in one step" do
    visit account_path(@account)

    assert_selector "[data-section=account-holdings]"
    click_on "VOO"

    assert_selector "[role=dialog]"
    assert_text "VOO"
    assert_text @account.name
    assert_field "Quantity", with: "50.0"
  end
end
