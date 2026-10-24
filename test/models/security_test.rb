require "test_helper"

class SecurityTest < ActiveSupport::TestCase
  test "a duplicate ticker without exchange is rejected" do
    Security.create!(ticker: "VOO", identifier: "Vanguard S&P 500", currency: "USD")

    duplicate = Security.new(ticker: "VOO", currency: "USD")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:ticker], "has already been taken"
  end

  test "the same ticker can exist on different exchanges" do
    Security.create!(ticker: "BOA", exchange: "NYSE", currency: "USD")

    other = Security.new(ticker: "BOA", exchange: "NASDAQ", currency: "USD")

    assert other.valid?
    other.save!
    assert_equal 2, Security.where(ticker: "BOA").count
  end

  test "the same ticker and exchange together are rejected" do
    Security.create!(ticker: "BOA", exchange: "NYSE", currency: "USD")

    duplicate = Security.new(ticker: "BOA", exchange: "NYSE", currency: "USD")

    assert_not duplicate.valid?
  end

  test "exchange is normalized and blank means no exchange" do
    security = Security.create!(ticker: "voo", exchange: "  ", currency: "USD")

    assert_equal "VOO", security.ticker
    assert_nil security.exchange
  end

  test "a security requires only a ticker and defaults its currency through the helper" do
    security = Security.find_or_create_by_identity!(ticker: "xyz")

    assert_equal "XYZ", security.ticker
    assert_equal "USD", security.currency
    assert_nil security.identifier
  end

  test "an existing ticker is reused instead of duplicated" do
    shared = Security.create!(ticker: "VOO", currency: "USD", note: "core index")

    reused = Security.find_or_create_by_identity!(ticker: "voo")

    assert_equal shared.id, reused.id
    assert_equal "core index", reused.note
    assert_equal 1, Security.where(ticker: "VOO").count
  end

  test "a note supplied while reusing updates the shared note" do
    shared = Security.create!(ticker: "VOO", currency: "USD")

    Security.find_or_create_by_identity!(ticker: "VOO", note: "household core")

    assert_equal "household core", shared.reload.note
  end

  test "a note change is reflected wherever the security appears" do
    shared = Security.create!(ticker: "VOO", currency: "USD", note: "before")
    fidelity = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    user = create_user
    PositionObservation.revise_current!({ account: fidelity, security: shared }, observed_on: Date.current, updated_by: user, quantity: 1, cost_basis: 1)
    PositionObservation.revise_current!({ account: schwab, security: shared }, observed_on: Date.current, updated_by: user, quantity: 2, cost_basis: 2)

    shared.update!(note: "after")

    assert_equal [ "after", "after" ], [ shared.reload.note, Security.find(shared.id).note ]
    assert_equal [ shared.id, shared.id ], PositionObservation.where(security: shared).order(:account_id).pluck(:security_id)
  end
end
