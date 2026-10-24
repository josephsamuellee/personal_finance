require "test_helper"

class FinancialHistoryTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @account = Account.create!(name: "Brokerage", account_type: "brokerage", currency: "USD")
    @security = Security.create!(ticker: "VOO", identifier: "922908769", currency: "USD")
    @scope = { account: @account, security: @security }
  end

  test "account types and archive hide entry choices without deleting history" do
    Account::TYPES.each do |type|
      account = Account.create!(name: type, account_type: type, currency: "USD")
      assert account.persisted?
    end
    observation = AccountObservation.revise_current!({ account: @account }, observed_on: Date.new(2021, 8, 15), updated_by: @user, amount: 10)
    @account.archive!

    assert_not_includes Account.available_for_entry, @account
    assert AccountObservation.kept.exists?(observation.id)
  end

  test "an ordinary save revises the current row and an explicit add allocates the next sequence" do
    first = PositionObservation.revise_current!(@scope, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 50, cost_basis: 1000)
    revised = PositionObservation.revise_current!(@scope, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 51, cost_basis: 1000)

    assert_equal first.id, revised.id
    assert_equal 1, revised.sequence
    added = PositionObservation.add_another!(@scope, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 55, cost_basis: 1100)

    assert_equal 2, added.sequence
    assert_equal 55, PositionObservation.current_on(@scope, Date.new(2026, 3, 15)).quantity
  end

  test "correcting a 2021 quantity keeps the financial date and stores the previous quantity" do
    observation = PositionObservation.revise_current!(@scope, observed_on: Date.new(2021, 8, 15), updated_by: @user, quantity: 50, cost_basis: 1000)
    observation.revision_user = @user
    observation.update!(quantity: 55, updated_by: @user)

    assert_equal 2021, observation.reload.observed_on.year
    assert_equal 55, observation.quantity
    assert_equal 50, observation.record_revisions.last.previous_values["quantity"].to_d
    assert_equal @user, observation.record_revisions.last.user
  end

  test "carry forward, same-day order, closed quantity, and unknown history" do
    PositionObservation.revise_current!(@scope, observed_on: Date.new(2026, 3, 15), updated_by: @user, quantity: 50, cost_basis: 1000)
    state, row = PositionObservation.state_on(@scope, Date.new(2026, 10, 21))

    assert_equal :carried_forward, state
    assert_equal 50, row.quantity

    PositionObservation.revise_current!(@scope, observed_on: Date.new(2026, 4, 1), updated_by: @user, quantity: 0, cost_basis: 0)
    closed_state, closed = PositionObservation.state_on(@scope, Date.new(2026, 10, 21))

    assert_equal :carried_forward, closed_state
    assert_equal 0, closed.quantity
    assert closed.closed?

    other = Security.create!(ticker: "QQQ", identifier: "QQQ", currency: "USD")
    unknown, missing = PositionObservation.state_on({ account: @account, security: other }, Date.new(2026, 10, 21))

    assert_equal :unknown, unknown
    assert_nil missing
  end

  test "debt balances are nonnegative and reports subtract them" do
    debt = Account.create!(name: "Mortgage", account_type: "debt", currency: "USD")
    observation = AccountObservation.new(account: debt, observed_on: Date.current, sequence: 1, amount: -1)
    assert_not observation.valid?

    AccountObservation.revise_current!({ account: debt }, observed_on: Date.new(2026, 10, 1), updated_by: @user, amount: 100_000)
    AccountObservation.revise_current!({ account: @account }, observed_on: Date.new(2026, 10, 1), updated_by: @user, amount: 1_000)
    snapshot = Reporting::Snapshot.new(on: Date.new(2026, 10, 1))

    assert_equal BigDecimal("-99000"), snapshot.net_worth
  end

  test "backdated observations stay on their financial date" do
    observation = AccountObservation.revise_current!({ account: @account }, observed_on: Date.new(2021, 8, 15), updated_by: @user, amount: 20)

    assert_equal Date.new(2021, 8, 15), observation.observed_on
    assert_operator observation.created_at, :>, Date.new(2021, 12, 31)
  end
end
