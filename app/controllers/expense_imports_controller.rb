class ExpenseImportsController < ApplicationController
  def new
    @batches = ImportBatch.order(created_at: :desc).limit(10)
  end

  def create
    mapping = mapping_params
    upload = params[:file]
    upload.rewind if upload.respond_to?(:rewind)
    rows = ExpenseCsv.parse(upload, mapping)
    token = SecureRandom.hex(16)
    session[:expense_import_token] = token
    ExpenseImportDraft.write(token, {
      "filename" => params[:file].original_filename,
      "mapping" => mapping,
      "rows" => rows.map { |row| serialize_row(row) }
    })
    redirect_to preview_expense_imports_path
  end

  def preview
    @draft = ExpenseImportDraft.read(session[:expense_import_token])
    redirect_to new_expense_import_path, alert: "Upload a CSV first." if @draft.nil?
  end

  def confirm
    draft = ExpenseImportDraft.read(session[:expense_import_token])
    return redirect_to(new_expense_import_path, alert: "Upload a CSV first.") if draft.nil?

    excluded = Array(params[:exclude]).map(&:to_i)
    rows = draft["rows"]
    blocking = rows.reject { |row| excluded.include?(row["line"]) || row["errors"].blank? }
    if blocking.any?
      @draft = draft
      flash.now[:alert] = "Resolve or exclude invalid rows before importing."
      render :preview, status: :unprocessable_entity
      return
    end

    imported = rows.reject { |row| excluded.include?(row["line"]) || row["errors"].present? }
    ActiveRecord::Base.transaction do
      batch = ImportBatch.create!(
        user: current_user,
        status: "imported",
        column_mapping: draft["mapping"],
        original_filename: draft["filename"]
      )
      imported.each { |row| create_expense(batch, row) }
    end
    ExpenseImportDraft.delete(session[:expense_import_token])
    session.delete(:expense_import_token)
    redirect_to expenses_path, notice: "Import finished."
  end

  def cancel
    ExpenseImportDraft.delete(session[:expense_import_token])
    session.delete(:expense_import_token)
    redirect_to expenses_path, notice: "Import canceled."
  end

  def reverse
    batch = ImportBatch.find(params[:id])
    ActiveRecord::Base.transaction do
      batch.expenses.kept.find_each { |expense| expense.discard_from_active_use!(user: current_user) }
      batch.update!(status: "reversed", reversed_at: Time.current)
    end
    redirect_to expenses_path, notice: "Import reversed."
  end

  private
    def mapping_params
      params.require(:mapping).permit(:date, :amount, :category, :merchant, :notes, :kind).to_h
    end

    def serialize_row(row)
      {
        "line" => row.line,
        "spent_on" => row.spent_on&.iso8601,
        "amount" => row.amount&.to_s,
        "category_name" => row.category_name,
        "merchant" => row.merchant,
        "notes" => row.notes,
        "kind" => row.kind,
        "errors" => row.errors
      }
    end

    def create_expense(batch, row)
      Expense.create!(
        kind: row["kind"],
        amount: row["amount"],
        spent_on: row["spent_on"],
        category_name: row["category_name"],
        merchant: row["merchant"],
        notes: row["notes"],
        import_batch: batch,
        created_by: current_user,
        updated_by: current_user
      )
    end
end
