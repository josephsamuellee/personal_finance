require "test_helper"

class HoldingsImportOpenHoldingsTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD")
    @msft = Security.find_or_create_by_identity!(ticker: "MSFT", currency: "USD")
    @bnd = Security.find_or_create_by_identity!(ticker: "BND", currency: "USD")
  end

  def observe(account, security, quantity, on: Date.current)
    PositionObservation.revise_current!({ account:, security: }, observed_on: on, updated_by: @user, quantity:, cost_basis: quantity * 10)
  end

  test "lists nonzero current holdings in active brokerage accounts, including carried-forward ones" do
    observe(@schwab, @voo, 10)
    observe(@schwab, @msft, 3, on: 3.months.ago.to_date)
    observe(@schwab, @bnd, 4, on: 1.month.ago.to_date)
    observe(@schwab, @bnd, 0)
    archived = Account.create!(name: "Old", account_type: "brokerage", currency: "USD")
    observe(archived, @voo, 7)
    archived.archive!

    holdings = HoldingsImport::OpenHoldings.on(Date.current)

    assert_equal [ [ @schwab, @msft, 3 ], [ @schwab, @voo, 10 ] ],
                 holdings.map { |holding| [ holding.account, holding.security, holding.observation.quantity.to_i ] }
  end

  test "ignores observations dated after the given date" do
    observe(@schwab, @voo, 10, on: Date.current)

    assert_empty HoldingsImport::OpenHoldings.on(Date.yesterday)
  end
end
