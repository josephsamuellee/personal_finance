require "test_helper"

class ExpenseImportTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as(@user)
  end

  def csv_upload(contents)
    file = Tempfile.new([ "expenses", ".csv" ])
    file.write(contents)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, "text/csv")
  end

  test "cancel inserts nothing and invalid rows are identified before confirm" do
    csv = <<~CSV
      date,amount,category,merchant,notes,kind
      2026-10-02,12.50,Groceries,,,spending
      2026-10-03,nope,Groceries,,,spending
    CSV
    post expense_imports_path, params: {
      file: csv_upload(csv),
      mapping: { date: "date", amount: "amount", category: "category", merchant: "merchant", notes: "notes", kind: "kind" }
    }
    follow_redirect!
    assert_includes response.body, "invalid"

    assert_no_difference "Expense.count" do
      delete cancel_expense_imports_path
    end
  end

  test "reversal removes imported expenses from spending and keeps audit history" do
    csv = <<~CSV
      date,amount,category,merchant,notes,kind
      2026-10-02,12.50,Groceries,,,spending
    CSV
    post expense_imports_path, params: {
      file: csv_upload(csv),
      mapping: { date: "date", amount: "amount", category: "category", merchant: "merchant", notes: "notes", kind: "kind" }
    }
    post confirm_expense_imports_path
    expense = Expense.last
    batch = expense.import_batch
    post reverse_expense_import_path(batch)

    assert expense.reload.discarded_at
    assert_equal 0, Reporting::Spending.total(Date.new(2026, 10, 1)..Date.new(2026, 10, 31))
    assert expense.record_revisions.exists?
  end
end
