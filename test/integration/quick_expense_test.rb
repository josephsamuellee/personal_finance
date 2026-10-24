require "test_helper"

class QuickExpenseTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    @category = ExpenseCategory.create!(name: "Pantry")
    @existing = Expense.create!(
      kind: "spending", amount: 3, spent_on: Date.new(2026, 1, 2), merchant: "Old Shop",
      expense_category: @category, created_by: @user, updated_by: @user
    )
    @existing.revision_user = @user
    @existing.update!(merchant: "Hidden Deli", updated_by: @user)
    @existing.receipts.attach(io: StringIO.new("%PDF-SECRET"), filename: "secret.pdf", content_type: "application/pdf")
    @account = Account.create!(name: "Vault Checking", account_type: "checking", currency: "USD")
    AccountObservation.revise_current!({ account: @account }, observed_on: Date.current, updated_by: @user, amount: "4242.42")
    security = Security.create!(ticker: "SECRET", identifier: "SECRET", currency: "USD")
    PositionObservation.revise_current!({ account: @account, security: }, observed_on: Date.current, updated_by: @user, quantity: 1, cost_basis: 1)
    @revision_count = @existing.record_revisions.count
  end

  test "anonymous quick expense form has the entry fields and no household records" do
    get quick_expense_path

    assert_response :success
    assert_select "input[name=?]", "expense[amount]"
    assert_select "input[name=?]", "expense[category_name]"
    assert_select "input[name=?][value=?]", "expense[spent_on]", Date.current.iso8601
    assert_select "input[name=?]", "expense[merchant]"
    assert_select "textarea[name=?]", "expense[notes]"
    assert_select "input[type=file][name=?]", "expense[receipts][]"
    assert_select "label", text: "Amount"
    assert_select "input.ui-field[name=?][placeholder=?]", "expense[amount]", "$1,000"
    assert_select "button.ui-button", text: "Save"
    assert_select "a", text: "Sign in"
    assert_select "a", text: "Home", count: 0
    assert_select "a", text: "Expenses", count: 0
    assert_select "a", text: "Assets", count: 0
    assert_select "a", text: "Review", count: 0
    assert_not_includes response.body, "Hidden Deli"
    assert_not_includes response.body, "Vault Checking"
    assert_not_includes response.body, "SECRET"
    assert_not_includes response.body, "4242.42"
    assert_not_includes response.body, "Tracked spending"
  end

  test "amount and category save a spending expense dated today with no merchant or receipt" do
    assert_difference -> { Expense.count }, 1 do
      post quick_expense_path, params: { expense: { amount: "18.25", category_name: "Groceries" } }, headers: { "HOST" => "serverlite" }
    end

    expense = Expense.order(:id).last
    assert_equal "spending", expense.kind
    assert_equal BigDecimal("18.25"), expense.amount
    assert_equal "Groceries", expense.expense_category.name
    assert_equal Date.current, expense.spent_on
    assert_nil expense.merchant
    assert_not expense.receipts.attached?
    assert_nil expense.created_by
  end

  test "an edited date, merchant, notes, and image or pdf receipt are stored" do
    png = Tempfile.new([ "receipt", ".png" ])
    png.binmode
    png.write("\x89PNG\r\n".b)
    png.rewind
    pdf = Tempfile.new([ "receipt", ".pdf" ])
    pdf.write("%PDF-1.4")
    pdf.rewind

    post quick_expense_path, params: {
      expense: {
        amount: "4.00", category_name: "Supplies", spent_on: "2024-05-02",
        merchant: "Corner", notes: "lunch",
        receipts: [
          Rack::Test::UploadedFile.new(png.path, "image/png", true, original_filename: "receipt.png"),
          Rack::Test::UploadedFile.new(pdf.path, "application/pdf", true, original_filename: "receipt.pdf")
        ]
      }
    }

    expense = Expense.order(:id).last
    assert_equal Date.new(2024, 5, 2), expense.spent_on
    assert_equal "Corner", expense.merchant
    assert_equal "lunch", expense.notes
    assert_equal %w[image/png application/pdf], expense.receipts.map { |receipt| receipt.content_type }
  end

  test "a successful save returns a blank form and a generic confirmation" do
    post quick_expense_path, params: { expense: { amount: "9.99", category_name: "Snacks" } }
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Expense saved. You can enter another."
    assert_not_includes response.body, "9.99"
    assert_not_includes response.body, "Hidden Deli"
    assert_not_includes response.body, "Tracked spending"
    assert_select "input[name=?]", "expense[amount]" do |fields|
      assert_nil fields.first["value"]
    end
  end

  test "refund, transfer, account, and record ids do not change the existing expense" do
    assert_difference -> { Expense.count }, 1 do
      post quick_expense_path, params: {
        id: @existing.id,
        expense: {
          id: @existing.id, amount: "8", category_name: "Snacks", kind: "transfer",
          refund_of_id: @existing.id, source_account_id: @account.id, destination_account_id: @account.id
        }
      }
    end

    created = Expense.order(:id).last
    @existing.reload
    assert_equal "Hidden Deli", @existing.merchant
    assert_equal BigDecimal("3"), @existing.amount
    assert_equal @revision_count, @existing.record_revisions.count
    assert_equal "spending", created.kind
    assert_nil created.refund_of_id
    assert_nil created.source_account_id
    assert_nil created.destination_account_id
  end

  test "a client user id is ignored and a real session is recorded" do
    other = create_user(email: "bea@example.com")
    post quick_expense_path, params: { expense: { amount: "2", category_name: "Coffee", created_by_id: other.id } }
    assert_nil Expense.order(:id).last.created_by

    sign_in_as(@user)
    post quick_expense_path, params: { expense: { amount: "2", category_name: "Tea", created_by_id: other.id } }
    assert_equal @user, Expense.order(:id).last.created_by
  end

  test "invalid public input keeps the amount and stores nothing" do
    [
      { amount: "12.50", category_name: "" },
      { amount: "", category_name: "Food" },
      { amount: "$1,000", category_name: "Food" },
      { amount: "0", category_name: "Food" },
      { amount: "abc", category_name: "Food" },
      { amount: "12.50", category_name: "Food", spent_on: "yesterday" }
    ].each do |fields|
      assert_no_difference -> { Expense.count } do
        post quick_expense_path, params: { expense: fields }
      end
      assert_response :unprocessable_entity
      assert_includes response.body, fields[:amount] if fields[:amount].present?
      assert_not_includes response.body, "Hidden Deli"
    end

    bad = Tempfile.new([ "notes", ".txt" ])
    bad.write("not-a-receipt")
    bad.rewind
    assert_no_difference -> { Expense.count } do
      post quick_expense_path, params: {
        expense: {
          amount: "12.50", category_name: "Food",
          receipts: [ Rack::Test::UploadedFile.new(bad.path, "text/plain", true, original_filename: "notes.txt") ]
        }
      }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, "12.50"
    assert_not_includes response.body, "Hidden Deli"
  end

  test "out of bounds category, merchant, notes, and date are rejected" do
    [
      { amount: "1", category_name: "a" * 81 },
      { amount: "1", category_name: "Food", merchant: "m" * 121 },
      { amount: "1", category_name: "Food", notes: "n" * 2001 },
      { amount: "1", category_name: "Food", spent_on: "1999-12-31" },
      { amount: "1", category_name: "Food", spent_on: "2101-01-01" }
    ].each do |fields|
      assert_no_difference -> { Expense.count } do
        post quick_expense_path, params: { expense: fields }
      end
      assert_response :unprocessable_entity
    end
  end

  test "a public submission without the request token stores nothing" do
    ActionController::Base.allow_forgery_protection = true

    assert_no_difference -> { Expense.count } do
      post quick_expense_path, params: { expense: { amount: "5", category_name: "Food" } }
    end
    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "the eleventh public submission from one address is refused" do
    assert_difference -> { Expense.count }, 10 do
      10.times do |index|
        post quick_expense_path, params: { expense: { amount: "1", category_name: "Throttle #{index}" } }
        assert_response :redirect
      end
    end

    assert_no_difference -> { Expense.count } do
      post quick_expense_path, params: { expense: { amount: "1", category_name: "Throttle extra" } }
    end
    assert_response :too_many_requests
    assert_equal "Too many expense submissions. Try again shortly.\n", response.body
    assert_not_includes response.body, "Hidden Deli"
    assert_not_includes response.body, "4242.42"
  end

  test "expense edit shows the saved amount as the field value" do
    sign_in_as(@user)
    get edit_expense_path(@existing)

    assert_response :success
    assert_select "input.ui-field[name=?]", "expense[amount]" do |fields|
      assert_equal "3.0", fields.first["value"]
      assert_nil fields.first["placeholder"]
    end
  end

  test "anonymous visitors cannot open protected financial pages or a receipt" do
    get expenses_path
    assert_private
    get expense_path(@existing)
    assert_private
    get edit_expense_path(@existing)
    assert_private
    patch expense_path(@existing), params: { expense: { merchant: "Nope" } }
    assert_private
    assert_equal "Hidden Deli", @existing.reload.merchant
    delete expense_path(@existing)
    assert_private
    assert Expense.exists?(@existing.id)
    get root_path
    assert_private
    get assets_path
    assert_private
    get rails_blob_path(@existing.receipts.first, disposition: "inline")
    assert_private
    assert_not_includes response.body, "%PDF-SECRET"
  end

  private
    def assert_private
      assert_response :redirect
      assert_redirected_to "/session/new"
      assert_not_includes response.body, "Hidden Deli"
      assert_not_includes response.body, "4242.42"
    end
end
