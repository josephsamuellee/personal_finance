require "test_helper"

class BulkHoldingsImportTest < ActionDispatch::IntegrationTest
  HEADER = HoldingCsv::BULK_HEADERS.join(",")

  setup do
    @user = create_user
    sign_in_as(@user)
    @schwab = Account.create!(name: "Schwab", account_type: "brokerage", currency: "USD")
    @fidelity = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD")
    @vti = Security.find_or_create_by_identity!(ticker: "VTI", currency: "USD")
    observe(@schwab, @voo, 40)
    observe(@fidelity, @vti, 12)
    MarketPrice.upsert_effective!(security: @voo, amount: 500, market_on: Date.current, currency: "USD", source: "manual")
    MarketPrice.upsert_effective!(security: @vti, amount: 250, market_on: Date.current, currency: "USD", source: "manual")
  end

  def observe(account, security, quantity)
    PositionObservation.revise_current!({ account:, security: }, observed_on: Date.current, updated_by: @user, quantity:, cost_basis: quantity * 10)
  end

  def csv_upload(contents)
    file = Tempfile.new([ "holdings", ".csv" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  def upload(body)
    post bulk_holdings_import_path, params: { file: csv_upload("#{HEADER}\n#{body}") }
    follow_redirect!
  end

  def current_fingerprint
    css_select("input[name=fingerprint]").first["value"]
  end

  test "unauthenticated visitors cannot export or upload" do
    delete session_path
    get export_bulk_holdings_import_path
    assert_redirected_to new_session_path
    assert_no_difference [ "PositionObservation.count", "ImportBatch.count" ] do
      post bulk_holdings_import_path, params: { file: csv_upload(HEADER) }
    end
    assert_redirected_to new_session_path
  end

  test "the export is today's holdings and is not cached" do
    get export_bulk_holdings_import_path

    assert_response :success
    assert_includes response.headers["Cache-Control"], "no-store"
    assert_equal HEADER, response.body.lines.first.strip
    assert_equal 3, response.body.lines.size
  end

  test "the instructions page states the rules and offers export and upload" do
    get bulk_holdings_import_path

    assert_response :success
    [ "one observation date", "quantity 0", "ignored", "account_id" ].each { |text| assert_includes response.body, text }
    assert_select "a[href=?]", export_bulk_holdings_import_path
    assert_select "form[action=?] input[type=file]", bulk_holdings_import_path
    assert_select "nav a[aria-current=page]", text: /Assets/
  end

  test "Assets links to bulk edit from the securities card" do
    get assets_path

    assert_select "#maintain-securities ~ div a[href=?]", bulk_holdings_import_path
  end

  test "an unchanged export uploads back with no errors or warnings" do
    get export_bulk_holdings_import_path
    post bulk_holdings_import_path, params: { file: csv_upload(response.body) }
    follow_redirect!

    assert_select "[data-row-status=error]", count: 0
    assert_select "[data-row-status=warning]", count: 0
    assert_select "[data-row-status=accepted]", count: 2
    assert_includes response.body, "no-op"
  end

  test "each row is marked accepted, warning, or error and errors disable Confirm" do
    upload(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,,41,400,,
      #{@fidelity.id},Wrong name,VTI,,USD,,12,120,,
      999999,Ghost,AAPL,,USD,,1,1,1,
    CSV

    assert_select "[data-row-status=accepted]", count: 1
    assert_select "[data-row-status=warning]", text: /Warning/, count: 1
    assert_select "[data-row-status=error]", text: /Error/, count: 1
    assert_select "button[disabled]", text: "Confirm import"
  end

  test "current holdings missing from the file are warned and not written" do
    upload("#{@schwab.id},Schwab,VOO,,USD,,41,400,,\n")

    assert_select "[data-row-status=warning]", text: /Fidelity.*VTI/m
    assert_difference -> { PositionObservation.where(account: @schwab).count } => 0,
                      -> { PositionObservation.where(account: @fidelity).count } => 0 do
      post confirm_bulk_holdings_import_path, params: { fingerprint: current_fingerprint }
    end
    assert_equal 41, PositionObservation.current_on({ account: @schwab, security: @voo }, Date.current).quantity
    follow_redirect!
    assert_includes response.body, "ignored 1"
  end

  test "a warnings-only file commits to the account_id account" do
    upload(<<~CSV)
      #{@schwab.id},Schwab,VOO,,USD,,40,400,,
      #{@fidelity.id},Wrong name,VTI,,USD,,15,150,,
    CSV

    assert_difference -> { ImportBatch.where(kind: "holdings_bulk").count } => 1 do
      post confirm_bulk_holdings_import_path, params: { fingerprint: current_fingerprint }
    end
    assert_equal 15, PositionObservation.current_on({ account: @fidelity, security: @vti }, Date.current).quantity
  end

  test "uploading a corrected CSV replaces the attempt and saves nothing" do
    upload("999999,Ghost,VOO,,USD,,1,1,1,\n")
    assert_select "[data-row-status=error]", count: 1

    assert_no_difference [ "PositionObservation.count", "ImportBatch.count" ] do
      upload("#{@schwab.id},Schwab,VOO,,USD,,41,400,,\n")
    end
    assert_select "[data-row-status=error]", count: 0
    assert_select "li", text: /Ghost/, count: 0
  end

  test "cancel writes nothing" do
    upload("#{@schwab.id},Schwab,VOO,,USD,,41,400,,\n")

    assert_no_difference "PositionObservation.count" do
      delete cancel_bulk_holdings_import_path
    end
    assert_redirected_to assets_path
  end

  test "an account archived after review is rejected on confirm" do
    upload("#{@schwab.id},Schwab,VOO,,USD,,41,400,,\n")
    fingerprint = current_fingerprint
    @schwab.archive!

    assert_no_difference "PositionObservation.count" do
      post confirm_bulk_holdings_import_path, params: { fingerprint: }
    end
    assert_response :unprocessable_entity
  end
end
