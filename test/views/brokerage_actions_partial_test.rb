require "test_helper"

class BrokerageActionsPartialTest < ActionView::TestCase
  test "the 2 by 3 reading order ends with an empty cell" do
    account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    render "accounts/brokerage_actions", account:, on: Date.current, id_suffix: "-#{account.id}"

    labels = css_select("[data-section=brokerage-actions] a, [data-section=brokerage-actions] button").map { |node| node.text.strip }
    assert_equal [ "Add Holding", "Update Holdings via CSV", "Record Cash", "Update prices", "Remove Account" ], labels
    assert_select "#add-holding-#{account.id}"
    assert_select "#update-holdings-csv-#{account.id}"
    assert_select "#record-cash-#{account.id}"
    assert_select "#update-prices-#{account.id}"
    assert_select "#remove-account-#{account.id}"
    assert_select "[data-empty-cell]"
  end
end
