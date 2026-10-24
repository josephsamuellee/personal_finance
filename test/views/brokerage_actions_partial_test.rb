require "test_helper"

class BrokerageActionsPartialTest < ActionView::TestCase
  test "routine actions are a 2 by 2 and Remove Account is a footer" do
    account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    render "accounts/brokerage_actions", account:, on: Date.current, id_suffix: "-#{account.id}"

    labels = css_select("[aria-label='Brokerage actions'] a, [aria-label='Brokerage actions'] button").map { |node| node.text.strip }
    assert_equal [ "Add Holding", "Update Holdings via CSV", "Record Cash", "Update prices" ], labels
    assert_select "#add-holding-#{account.id}.ui-button-quiet"
    assert_select "#add-holding-#{account.id}.ui-button", count: 0
    assert_select "[data-empty-cell]", count: 0
    assert_select "[data-section=brokerage-archive] #remove-account-#{account.id}"
  end
end
