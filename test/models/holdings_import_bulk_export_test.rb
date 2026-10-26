require "csv"
require "test_helper"

class HoldingsImportBulkExportTest < ActiveSupport::TestCase
  setup do
    @user = create_user
    @schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD", note: "Core")
    PositionObservation.revise_current!({ account: @schwab, security: @voo }, observed_on: 3.months.ago.to_date,
                                        updated_by: @user, quantity: 40, cost_basis: 18_000.5)
  end

  def export
    CSV.parse(HoldingsImport::BulkExport.new(on: Date.current).to_csv, headers: true)
  end

  test "exports today's open holdings in the bulk header order with a blank price" do
    MarketPrice.upsert_effective!(security: @voo, amount: 512.25, market_on: 1.week.ago.to_date, currency: "USD", source: "manual")
    table = export

    assert_equal HoldingCsv::BULK_HEADERS, table.headers
    row = table.first
    assert_equal [ @schwab.id.to_s, "Schwab", "VOO", "Core", "USD", Date.current.iso8601, "40", "18000.5", nil, "512.25" ],
                 row.fields
  end

  test "last_price is blank when no price exists" do
    assert_nil export.first["last_price"]
  end

  test "formula-leading text is exported as text" do
    @schwab.update!(name: "=HYPERLINK(\"x\")")
    @voo.update!(note: "+1 lot")

    row = export.first
    assert_equal "'=HYPERLINK(\"x\")", row["account_name"]
    assert_equal "'+1 lot", row["note"]
  end

  test "an exported formula-safe name and note read back unchanged" do
    @schwab.update!(name: "=Brokerage")
    @voo.update!(note: "@risk")
    result = HoldingCsv.parse_bulk(HoldingsImport::BulkExport.new(on: Date.current).to_csv, captured_on: Date.current)
    row = result.rows.first

    assert_empty row.warnings
    assert_equal "@risk", row.note
  end
end
