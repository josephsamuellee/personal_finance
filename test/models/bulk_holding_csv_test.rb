require "test_helper"

class BulkHoldingCsvTest < ActiveSupport::TestCase
  HEADER = "account_id,account_name,ticker,note,currency,observation_date,quantity,cost_basis,price_per_share,last_price".freeze

  setup do
    @captured = Date.new(2026, 10, 23)
    @schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @fidelity = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
  end

  def parse(body, header: HEADER)
    HoldingCsv.parse_bulk("#{header}\n#{body}", captured_on: @captured)
  end

  test "rows carry their own accounts" do
    result = parse(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,2026-10-23,10,1000,,
      #{@fidelity.id},Fidelity,BND,,USD,2026-10-23,5,500,,
    CSV

    assert result.valid?
    assert_equal [ @schwab, @fidelity ], result.rows.map(&:account)
  end

  test "headers must be in the export order" do
    result = parse("", header: HEADER.split(",").rotate.join(","))

    assert_includes result.file_errors.join, "account_id, account_name, ticker"
  end

  test "last_price is ignored" do
    result = parse("#{@schwab.id},Schwab,VOO,,USD,2026-10-23,10,1000,,512.5\n")

    assert result.valid?
    assert_nil result.rows.first.price_per_share
  end

  test "a leading UTF-8 byte-order mark is accepted" do
    result = parse("#{@schwab.id},Schwab,VOO,,USD,2026-10-23,10,1000,,\n", header: "﻿#{HEADER}")

    assert result.valid?
  end

  test "a blank, unknown, archived, or non-brokerage account is a row error" do
    archived = Account.create!(name: "Old", account_type: "brokerage", currency: "USD", archived_at: 1.day.ago)
    checking = Account.create!(name: "Checking", account_type: "checking", currency: "USD")
    result = parse(<<~CSV)
      ,Schwab,VOO,,USD,2026-10-23,10,1000,,
      999999,Ghost,VOO,,USD,2026-10-23,10,1000,,
      #{archived.id},Old,VOO,,USD,2026-10-23,10,1000,,
      #{checking.id},Checking,VOO,,USD,2026-10-23,10,1000,,
    CSV

    assert_includes result.rows[0].errors.join, "account_id is required"
    assert_includes result.rows[1].errors.join, "Account 999999 was not found"
    assert_includes result.rows[2].errors.join, "archived"
    assert_includes result.rows[3].errors.join, "not a brokerage account"
    assert result.rows.all? { |row| row.account.nil? }
  end

  test "a mismatched account name is a warning and the id wins" do
    result = parse("#{@schwab.id},Fidelity,VOO,,USD,2026-10-23,10,1000,,\n")
    row = result.rows.first

    assert row.valid?
    assert_equal @schwab, row.account
    assert_includes row.warnings.join, "Schwab"
    assert_includes row.warnings.join, "Fidelity"
  end

  test "more than one observation date blocks the file and names the rows" do
    result = parse(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,2021-01-01,10,1000,,
      #{@schwab.id},Schwab,VTI,,USD,2021-01-01,10,1000,,
      #{@fidelity.id},Fidelity,BND,,USD,2021-02-01,5,500,,
    CSV

    assert_not result.valid?
    message = result.rows.first.errors.join
    assert_includes message, "2021-01-01 (rows 2, 3)"
    assert_includes message, "2021-02-01 (row 4)"
  end

  test "blank dates all resolve to the session date" do
    result = parse(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,,10,1000,,
      #{@fidelity.id},Fidelity,BND,,USD,,5,500,,
    CSV

    assert result.valid?
    assert_equal [ @captured, @captured ], result.rows.map(&:observation_date)
  end

  test "a duplicate security within one account is blocked" do
    result = parse(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,2026-10-23,10,1000,,
      #{@schwab.id},Schwab,VOO,,USD,2026-10-23,11,1000,,
      #{@fidelity.id},Fidelity,VOO,,USD,2026-10-23,5,500,,
    CSV

    assert_not result.rows[0].valid?
    assert_not result.rows[1].valid?
    assert result.rows[2].valid?
  end
end
