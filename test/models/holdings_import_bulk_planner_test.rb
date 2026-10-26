require "test_helper"

class HoldingsImportBulkPlannerTest < ActiveSupport::TestCase
  HEADER = HoldingCsv::BULK_HEADERS.join(",")

  setup do
    @user = create_user
    @schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @fidelity = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD")
    @vti = Security.find_or_create_by_identity!(ticker: "VTI", currency: "USD")
    observe(@schwab, @voo, 40)
    observe(@schwab, @vti, 12)
  end

  def observe(account, security, quantity, on: Date.current)
    PositionObservation.revise_current!({ account:, security: }, observed_on: on, updated_by: @user, quantity:, cost_basis: quantity * 10)
  end

  def planner(body)
    rows = HoldingCsv.parse_bulk("#{HEADER}\n#{body}", captured_on: Date.current).rows
    HoldingsImport::BulkPlanner.new(captured_on: Date.current, rows:)
  end

  test "current open holdings absent from the upload are listed as missing" do
    bulk = planner("#{@schwab.id},Schwab,VOO,,USD,2021-01-01,10,100,90,\n")

    assert_equal [ [ @schwab, @vti ] ], bulk.missing.map { |holding| [ holding.account, holding.security ] }
  end

  test "a holding in the upload under another account is still missing from its own account" do
    bulk = planner(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,2021-01-01,10,100,90,
      #{@fidelity.id},Fidelity,VTI,,USD,2021-01-01,1,100,80,
    CSV

    assert_equal [ [ @schwab, @vti ] ], bulk.missing.map { |holding| [ holding.account, holding.security ] }
  end

  test "a holding opened after review changes the fingerprint" do
    bulk = planner("#{@schwab.id},Schwab,VOO,,USD,2021-01-01,10,100,90,\n")
    before = bulk.fingerprint
    observe(@fidelity, @voo, 3)

    assert_not_equal before, planner("#{@schwab.id},Schwab,VOO,,USD,2021-01-01,10,100,90,\n").fingerprint
  end

  def commit(body, **options)
    rows = HoldingCsv.parse_bulk("#{HEADER}\n#{body}", captured_on: Date.current).rows
    fingerprint = HoldingsImport::BulkPlanner.new(captured_on: Date.current, rows:).fingerprint
    HoldingsImport::Commit.new(
      user: @user, captured_on: Date.current, rows:, authorized_price_keys: [], historical_ack: "1",
      fingerprint:, batch_kind: "holdings_bulk", planner_class: HoldingsImport::BulkPlanner, **options
    ).call
  end

  test "a historical bulk commit writes each account, closes zero rows, and skips missing holdings" do
    result = commit(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,2021-01-01,0,0,90,
      #{@fidelity.id},Fidelity,VOO,,USD,2021-01-01,4,320,90,
    CSV
    day = Date.new(2021, 1, 1)

    assert_equal :ok, result.status
    assert PositionObservation.current_on({ account: @schwab, security: @voo }, day).closed?
    assert_equal 4, PositionObservation.current_on({ account: @fidelity, security: @voo }, day).quantity
    assert_nil PositionObservation.current_on({ account: @schwab, security: @vti }, day)
    assert_equal [ "holdings_bulk", nil ], [ result.batch.kind, result.batch.account_id ]
  end

  test "a write failure rolls back every account" do
    calls = 0
    original = HoldingForm.instance_method(:save!)
    HoldingForm.define_method(:save!) do
      calls += 1
      raise ActiveRecord::StatementInvalid, "boom" if calls == 2

      original.bind_call(self)
    end

    assert_no_difference [ "PositionObservation.count", "ImportBatch.count" ] do
      assert_raises(ActiveRecord::StatementInvalid) do
        commit(<<~CSV)
          #{@schwab.id},Schwab,VOO,,USD,2021-01-01,1,10,90,
          #{@fidelity.id},Fidelity,VOO,,USD,2021-01-01,4,320,90,
        CSV
      end
    end
  ensure
    HoldingForm.define_method(:save!, original)
  end
end
