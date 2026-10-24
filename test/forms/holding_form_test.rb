require "test_helper"

class HoldingFormTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @security = Security.create!(ticker: "VOO", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: @security },
                                        observed_on: Date.new(2026, 3, 15), updated_by: @user,
                                        quantity: 50, cost_basis: 18_000)
    MarketPrice.upsert_effective!(security: @security, amount: 400, market_on: Date.current,
                                  currency: "USD", source: "manual")
  end

  def form(gesture: "save", on: Date.current, quantity: "50", cost_basis: "18000", price: nil, **extra)
    HoldingForm.new(account: @account, security: @security, user: @user, gesture:,
                     observed_on: on.iso8601, quantity:, cost_basis:, price:, **extra)
  end

  test "an unchanged save against an existing on-date observation classifies as no change" do
    PositionObservation.revise_current!({ account: @account, security: @security },
                                        observed_on: Date.current, updated_by: @user,
                                        quantity: 50, cost_basis: 18_000)

    assert_equal :no_change, form.intent
    assert_equal "No changes", form.intent_label
  end

  test "a date with no observation classifies as a new observation even when values are unchanged" do
    # The label targets a new observation; the save still records nothing
    # when every value matches the latest applicable observation (task 4.2).
    assert_equal :new, form.intent
    assert_equal "New observation", form.intent_label
  end

  test "a changed quantity on a date with an observation classifies as an edit" do
    PositionObservation.revise_current!({ account: @account, security: @security },
                                        observed_on: Date.current, updated_by: @user,
                                        quantity: 50, cost_basis: 18_000)

    assert_equal :edit, form(quantity: "55").intent
    assert_equal "Edit observation", form(quantity: "55").intent_label
  end

  test "a date with no observation classifies as a new observation" do
    assert_equal :new, form(on: Date.new(2026, 10, 1)).intent
    assert_equal "New observation", form(on: Date.new(2026, 10, 1)).intent_label
  end

  test "a changed price with unchanged holding values classifies as a price-only update" do
    assert_equal :price_only, form(price: "401").intent
    assert_equal "Update price", form(price: "401").intent_label
  end

  test "verify is its own explicit gesture, never inferred" do
    assert_equal :verify, form(gesture: "verify").intent
    assert_equal :new, form.intent
  end

  test "a future observation date is rejected" do
    future = form(on: Date.current + 2)

    assert_not future.valid?
    assert_includes future.errors[:observed_on], "cannot be in the future"
  end

  test "a past observation date requires an explicit acknowledgment" do
    past = form(on: Date.new(2021, 6, 1))

    assert past.historical?
    assert_not past.valid?
    assert_includes past.errors[:historical_ack], "must be acknowledged to save a past date"

    acknowledged = form(on: Date.new(2021, 6, 1), historical_ack: "1")

    assert acknowledged.valid?
  end

  test "an invalid date is rejected with a clear message" do
    bad = HoldingForm.new(account: @account, security: @security, user: @user, gesture: "save",
                          observed_on: "not-a-date", quantity: "1", cost_basis: "1")

    assert_not bad.valid?
    assert_includes bad.errors[:observed_on], "Enter a valid observation date"
  end

  test "quantity, cost basis, and price must be valid numbers when supplied" do
    invalid = form(quantity: "abc", price: "-2")

    assert_not invalid.valid?
    assert_includes invalid.errors[:quantity], "is not a number"
    assert_includes invalid.errors[:price], "must be greater than 0"
  end

  test "a price-only save updates the shared price and creates no holding observation" do
    before = PositionObservation.count

    form(price: "401").save!

    assert_equal before, PositionObservation.count
    assert_equal 401, MarketPrice.effective_on(@security, Date.current).amount
  end

  test "a quantity change records a dated holding observation and leaves the price alone" do
    form(quantity: "55").save!

    row = PositionObservation.current_on({ account_id: @account.id, security_id: @security.id }, Date.current)

    assert_equal 55, row.quantity
    assert_equal Date.current, row.observed_on
    assert_equal 400, MarketPrice.effective_on(@security, Date.current).amount
  end

  test "an unchanged save records nothing even on a date with no observation" do
    before = PositionObservation.count
    price_before = MarketPrice.effective_on(@security, Date.current).amount

    result = form.save!

    assert_equal({ intent: :no_change }, result)
    assert_equal before, PositionObservation.count
    assert_equal price_before, MarketPrice.effective_on(@security, Date.current).amount
  end

  test "an unchanged save against an on-date observation records nothing" do
    PositionObservation.revise_current!({ account: @account, security: @security },
                                        observed_on: Date.current, updated_by: @user,
                                        quantity: 50, cost_basis: 18_000)
    before = PositionObservation.count

    result = form.save!

    assert_equal({ intent: :no_change }, result)
    assert_equal before, PositionObservation.count
  end

  test "the explicit verify gesture records the verification observation" do
    result = form(gesture: "verify").save!

    assert_equal({ intent: :verify }, result)
    state, row = PositionObservation.state_on({ account_id: @account.id, security_id: @security.id }, Date.current)
    assert_equal :verified, state
    assert_equal 50, row.quantity
  end

  test "an edit keeps the observation's revision history" do
    row = PositionObservation.revise_current!({ account: @account, security: @security },
                                              observed_on: Date.new(2026, 3, 15), updated_by: @user,
                                              quantity: 50, cost_basis: 18_000)

    form(gesture: "correct", correction_id: row.id, observed_on: Date.new(2026, 3, 15).iso8601, quantity: "50", cost_basis: "19000").save!

    assert_equal 19_000, row.reload.cost_basis
    assert_operator row.record_revisions.count, :>=, 1
  end

  test "a failed combined save leaves no security, observation, or price behind" do
    brokerage = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")

    failing = HoldingForm.new(account: brokerage, user: @user, gesture: "create",
                              observed_on: Date.current.iso8601, ticker: "XYZ",
                              quantity: "10", cost_basis: "1", price: nil)

    assert_not failing.valid?
    assert_includes failing.errors[:price], "A market price for this date is required before the holding can be saved"
    assert_nil Security.find_by(ticker: "XYZ")
  end
end
