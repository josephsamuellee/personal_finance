class HoldingsImportsController < ApplicationController
  before_action :set_account

  def new
  end

  def template
    send_data HoldingCsv.template, filename: "holdings-template.csv", type: "text/csv"
  end

  def create
    upload = params[:file]
    unless upload.respond_to?(:read)
      return redirect_to new_account_holdings_import_path(@account), alert: "Choose a CSV file."
    end

    captured_on = Date.current
    result = HoldingCsv.parse(upload, captured_on:)
    if result.file_errors.any?
      return redirect_to new_account_holdings_import_path(@account), alert: result.file_errors.to_sentence
    end

    token = SecureRandom.hex(16)
    session[:holdings_import_token] = token
    ExpenseImportDraft.write(token, {
      "account_id" => @account.id,
      "captured_on" => captured_on.iso8601,
      "filename" => upload.original_filename,
      "rows" => result.rows.map { |row| serialize_row(row) }
    })
    redirect_to preview_account_holdings_import_path(@account)
  end

  def preview
    load_draft or return
    @planned = planner.plan
    @fingerprint = planner.fingerprint(@planned)
  end

  def confirm
    load_draft or return
    authorized = Array(params[:authorize_price])
    commit = HoldingsImport::Commit.new(
      account: @account, user: current_user, captured_on: Date.iso8601(@draft["captured_on"]),
      rows: csv_rows, authorized_price_keys: authorized,
      historical_ack: params[:historical_ack], fingerprint: params[:fingerprint]
    ).call

    case commit.status
    when :ok
      ExpenseImportDraft.delete(session[:holdings_import_token])
      session.delete(:holdings_import_token)
      redirect_to account_path(@account), notice: summary(commit)
    when :stale
      @planned = commit.planned
      @fingerprint = HoldingsImport::Planner.new(
        account: @account, captured_on: Date.iso8601(@draft["captured_on"]),
        rows: csv_rows, authorized_price_keys: authorized
      ).fingerprint(@planned)
      flash.now[:alert] = "Holdings changed since preview. Review the updated plan."
      render :preview, status: :unprocessable_entity
    when :historical
      @planned = commit.planned
      @fingerprint = params[:fingerprint]
      flash.now[:alert] = "Acknowledge the historical observation dates before importing."
      render :preview, status: :unprocessable_entity
    else
      @planned = commit.planned
      @fingerprint = params[:fingerprint]
      flash.now[:alert] = "Resolve every row before importing. No holdings were saved."
      render :preview, status: :unprocessable_entity
    end
  end

  def cancel
    ExpenseImportDraft.delete(session[:holdings_import_token])
    session.delete(:holdings_import_token)
    redirect_to account_path(@account), notice: "Import canceled."
  end

  private
    def set_account
      @account = Account.available_for_entry.brokerage.find(params[:account_id])
    end

    def load_draft
      @draft = ExpenseImportDraft.read(session[:holdings_import_token])
      if @draft.nil? || @draft["account_id"] != @account.id
        redirect_to new_account_holdings_import_path(@account), alert: "Upload a CSV first."
        return false
      end
      true
    end

    def csv_rows
      @draft["rows"].map do |row|
        HoldingCsv::Row.new(
          line: row["line"], ticker: row["ticker"], note: row["note"], currency: row["currency"],
          observation_date: row["observation_date"] && Date.iso8601(row["observation_date"]),
          quantity: row["quantity"] && BigDecimal(row["quantity"]),
          cost_basis: row["cost_basis"] && BigDecimal(row["cost_basis"]),
          price_per_share: row["price_per_share"] && BigDecimal(row["price_per_share"]),
          errors: Array(row["errors"])
        )
      end
    end

    def planner
      HoldingsImport::Planner.new(
        account: @account, captured_on: Date.iso8601(@draft["captured_on"]),
        rows: csv_rows, authorized_price_keys: Array(params[:authorize_price])
      )
    end

    def serialize_row(row)
      {
        "line" => row.line, "ticker" => row.ticker, "note" => row.note, "currency" => row.currency,
        "observation_date" => row.observation_date&.iso8601,
        "quantity" => row.quantity&.to_s, "cost_basis" => row.cost_basis&.to_s,
        "price_per_share" => row.price_per_share&.to_s, "errors" => row.errors
      }
    end

    def summary(commit)
      created = commit.planned.count { |row| row.outcomes.include?("new holding") || row.outcomes.include?("new security") }
      updated = commit.planned.count { |row| row.outcomes.include?("updated observation") || row.outcomes.include?("price change") }
      unchanged = commit.planned.count(&:no_op?)
      "Import finished. Created #{created}, updated #{updated}, unchanged #{unchanged}. Batch #{commit.batch.id}."
    end
end
