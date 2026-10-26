class BulkHoldingsImportsController < ApplicationController
  def show
  end

  def export
    export = HoldingsImport::BulkExport.new(on: Date.current)
    if export.too_large?
      return redirect_to bulk_holdings_import_path, alert: "More than #{HoldingCsv::MAX_ROWS} holdings are open; the export would not upload back."
    end

    response.headers["Cache-Control"] = "no-store"
    send_data export.to_csv, filename: "holdings-#{Date.current.iso8601}.csv", type: "text/csv"
  end

  def create
    discard_draft
    upload = params[:file]
    return redirect_to bulk_holdings_import_path, alert: "Choose a CSV file." unless upload.respond_to?(:read)

    text = upload.read.to_s.force_encoding(Encoding::UTF_8)
    captured_on = Date.current
    result = HoldingCsv.parse_bulk(text, captured_on:)
    return redirect_to bulk_holdings_import_path, alert: result.file_errors.to_sentence if result.file_errors.any?

    # The raw CSV is kept and re-parsed so accounts and prices are revalidated at confirm time.
    token = SecureRandom.hex(16)
    session[:bulk_holdings_import_token] = token
    ExpenseImportDraft.write(token, { "captured_on" => captured_on.iso8601, "filename" => upload.original_filename, "csv" => text })
    redirect_to preview_bulk_holdings_import_path
  end

  def preview
    load_draft or return
    plan_review
  end

  def confirm
    load_draft or return
    ignored = planner.missing.size
    commit = HoldingsImport::Commit.new(
      user: current_user, captured_on:, rows: csv_rows, authorized_price_keys:,
      historical_ack: params[:historical_ack], fingerprint: params[:fingerprint],
      batch_kind: "holdings_bulk", planner_class: HoldingsImport::BulkPlanner
    ).call

    if commit.status == :ok
      discard_draft
      return redirect_to assets_path, notice: summary(commit, ignored)
    end

    plan_review
    flash.now[:alert] = {
      stale: "Holdings changed since review. Check the updated plan.",
      historical: "Acknowledge the historical observation date before importing."
    }.fetch(commit.status, "Resolve every error before importing. No holdings were saved.")
    render :preview, status: :unprocessable_entity
  end

  def cancel
    discard_draft
    redirect_to assets_path, notice: "Bulk import canceled."
  end

  private
    def load_draft
      @draft = ExpenseImportDraft.read(session[:bulk_holdings_import_token])
      return true if @draft

      redirect_to bulk_holdings_import_path, alert: "Upload a CSV first."
      false
    end

    def discard_draft
      ExpenseImportDraft.delete(session.delete(:bulk_holdings_import_token))
    end

    def captured_on
      Date.iso8601(@draft["captured_on"])
    end

    def csv_rows
      @csv_rows ||= HoldingCsv.parse_bulk(@draft["csv"], captured_on:).rows
    end

    def authorized_price_keys
      Array(params[:authorize_price])
    end

    def planner
      HoldingsImport::BulkPlanner.new(captured_on:, rows: csv_rows, authorized_price_keys:)
    end

    def plan_review
      bulk = planner
      @planned = bulk.plan
      @missing = bulk.missing(@planned)
      @fingerprint = bulk.fingerprint(@planned)
    end

    def summary(commit, ignored)
      created = commit.planned.count { |row| row.outcomes.include?("new holding") || row.outcomes.include?("new security") }
      updated = commit.planned.count { |row| row.outcomes.include?("updated observation") || row.outcomes.include?("price change") }
      unchanged = commit.planned.count(&:no_op?)
      "Bulk import finished. Created #{created}, updated #{updated}, unchanged #{unchanged}, ignored #{ignored}. Batch #{commit.batch.id}."
    end
end
