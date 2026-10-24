require "test_helper"

class HoldingCsvTest < ActiveSupport::TestCase
  setup do
    @captured = Date.new(2026, 10, 23)
  end

  test "a blank observation date uses the captured session date" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,100
    CSV
    result = HoldingCsv.parse(csv, captured_on: @captured)

    assert result.valid?
    assert_equal @captured, result.rows.first.observation_date
  end

  test "duplicate ticker and date rows are blocked with both line numbers" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,2026-10-23,10,1000,100
      VOO,,USD,2026-10-23,11,1100,100
    CSV
    result = HoldingCsv.parse(csv, captured_on: @captured)

    assert_not result.valid?
    assert_includes result.rows.first.errors.join, "2"
    assert_includes result.rows.first.errors.join, "3"
  end

  test "negative and non-numeric values are rejected and zero quantity is allowed" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,2026-10-23,-1,1000,100
      AAPL,,USD,2026-10-23,nope,1000,100
      MSFT,,USD,2026-10-23,0,0,10
    CSV
    result = HoldingCsv.parse(csv, captured_on: @captured)

    assert_not result.rows[0].valid?
    assert_not result.rows[1].valid?
    assert result.rows[2].valid?
    assert_equal 0, result.rows[2].quantity
  end

  test "an oversized file is rejected" do
    huge = "ticker,note,currency,observation_date,quantity,cost_basis,price_per_share\n" + ("X" * (HoldingCsv::MAX_BYTES + 10))
    result = HoldingCsv.parse(huge, captured_on: @captured)

    assert_includes result.file_errors.join, "1 MB"
  end

  test "the template has the required headers in order" do
    assert_equal "#{HoldingCsv::HEADERS.join(',')}\n", HoldingCsv.template
  end
end
