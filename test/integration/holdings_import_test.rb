require "test_helper"

class HoldingsImportTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
    @account = Account.create!(name: "Fidelity", account_type: "brokerage", currency: "USD")
    @voo = Security.find_or_create_by_identity!(ticker: "VOO", currency: "USD")
    MarketPrice.upsert_effective!(security: @voo, amount: 100, market_on: Date.current, currency: "USD", source: "manual")
  end

  def csv_upload(contents)
    file = Tempfile.new([ "holdings", ".csv" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  def upload(contents)
    post account_holdings_import_path(@account), params: { file: csv_upload(contents) }
  end

  test "skipping after a new brokerage account leaves it empty" do
    post accounts_path, params: { account: { name: "Schwab", account_type: "brokerage", currency: "USD" } }
    account = Account.find_by!(name: "Schwab")
    assert_redirected_to new_account_holdings_import_path(account)

    follow_redirect!
    assert_includes response.body, "Skip"
    get account_path(account)
    assert_response :success
    assert_equal 0, PositionObservation.where(account:).count
  end

  test "a failed CSV leaves the account and writes no holdings" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,nope,1000,100
    CSV
    assert_no_difference [ "PositionObservation.count", "MarketPrice.count" ] do
      upload(csv)
      follow_redirect!
      post confirm_account_holdings_import_path(@account), params: { fingerprint: "stale" }
    end
    assert Account.exists?(@account.id)
  end

  test "one invalid quantity blocks the whole file" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,100
      AAPL,,USD,,bad,1000,100
    CSV
    upload(csv)
    follow_redirect!
    assert_includes response.body, "Quantity is invalid"
    assert_no_difference "PositionObservation.count" do
      post confirm_account_holdings_import_path(@account), params: { fingerprint: session_fingerprint }
    end
  end

  test "a valid import creates a holding through HoldingForm and a holdings batch" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,Core,USD,,10,1000,
    CSV
    upload(csv)
    follow_redirect!
    fingerprint = session_fingerprint
    assert_difference -> { PositionObservation.count } => 1, -> { ImportBatch.where(kind: "holdings").count } => 1 do
      post confirm_account_holdings_import_path(@account), params: { fingerprint: }
    end
    assert_equal BigDecimal("10"), PositionObservation.current_on({ account: @account, security: @voo }, Date.current).quantity
    assert_equal "Core", @voo.reload.note
    assert_nil response.body[expense_imports_path]
  end

  test "cancel writes nothing" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,
    CSV
    upload(csv)
    assert_no_difference "PositionObservation.count" do
      delete cancel_account_holdings_import_path(@account)
    end
  end

  test "an identical reimport is a no-op" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,
    CSV
    upload(csv)
    follow_redirect!
    post confirm_account_holdings_import_path(@account), params: { fingerprint: session_fingerprint }
    upload(csv)
    follow_redirect!
    assert_includes response.body, "no-op"
    assert_no_difference "PositionObservation.count" do
      post confirm_account_holdings_import_path(@account), params: { fingerprint: session_fingerprint }
    end
  end

  test "a historical row requires acknowledgment" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,2021-06-01,10,1000,50
    CSV
    upload(csv)
    follow_redirect!
    fingerprint = session_fingerprint
    assert_no_difference "PositionObservation.count" do
      post confirm_account_holdings_import_path(@account), params: { fingerprint: }
    end
    post confirm_account_holdings_import_path(@account), params: { fingerprint:, historical_ack: "1" }
    assert_equal Date.new(2021, 6, 1), PositionObservation.where(account: @account).pick(:observed_on)
  end

  test "a stale price after preview returns to preview" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,
    CSV
    upload(csv)
    follow_redirect!
    fingerprint = session_fingerprint
    MarketPrice.upsert_effective!(security: @voo, amount: 200, market_on: Date.current, currency: "USD", source: "manual")
    post confirm_account_holdings_import_path(@account), params: { fingerprint: }
    assert_response :unprocessable_entity
    assert_includes response.body, "changed since preview"
  end

  test "a write failure rolls back the import" do
    csv = <<~CSV
      ticker,note,currency,observation_date,quantity,cost_basis,price_per_share
      VOO,,USD,,10,1000,
    CSV
    upload(csv)
    follow_redirect!
    HoldingForm.class_eval do
      alias_method :original_save!, :save!
      def save!
        raise ActiveRecord::StatementInvalid, "boom"
      end
    end
    assert_no_difference [ "PositionObservation.count", "ImportBatch.count" ] do
      assert_raises(ActiveRecord::StatementInvalid) do
        post confirm_account_holdings_import_path(@account), params: { fingerprint: session_fingerprint }
      end
    end
  ensure
    HoldingForm.class_eval do
      alias_method :save!, :original_save! if method_defined?(:original_save!)
    end
  end

  test "unauthenticated visitors cannot open the importer" do
    delete session_path
    get new_account_holdings_import_path(@account)
    assert_redirected_to new_session_path
    post account_holdings_import_path(@account)
    assert_redirected_to new_session_path
  end

  test "the template headers match the spec" do
    get template_account_holdings_import_path(@account)
    assert_equal 200, response.status
    assert_equal HoldingCsv::HEADERS.join(","), response.body.strip
  end

  def session_fingerprint
    draft = ExpenseImportDraft.read(@request.session[:holdings_import_token] || session[:holdings_import_token])
    rows = draft["rows"].map do |row|
      HoldingCsv::Row.new(
        line: row["line"], ticker: row["ticker"], note: row["note"], currency: row["currency"],
        observation_date: row["observation_date"] && Date.iso8601(row["observation_date"]),
        quantity: row["quantity"] && BigDecimal(row["quantity"]),
        cost_basis: row["cost_basis"] && BigDecimal(row["cost_basis"]),
        price_per_share: row["price_per_share"] && BigDecimal(row["price_per_share"]),
        errors: Array(row["errors"])
      )
    end
    HoldingsImport::Planner.new(account: @account, captured_on: Date.iso8601(draft["captured_on"]), rows:).fingerprint
  end
end
